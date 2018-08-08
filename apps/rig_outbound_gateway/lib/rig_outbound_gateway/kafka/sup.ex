defmodule RigOutboundGateway.Kafka.Sup do
  @moduledoc """
  Supervisor handling Kafka-related processes.

  ## About the Kafka Integration

  In order to scale horizontally,
  [Kafka Consumer Groups](https://kafka.apache.org/documentation/#distributionimpl)
  are used. This supervisor takes care of the [Brod](https://github.com/klarna/brod)
  client -- Brod is the library used for communicating with Kafka --, which holds the
  connection to one of the Kafka brokers. Brod also relies on a worker process called
  GroupSubscriber, which is also managed by the supervisor at hand.

  The consumer setup is done in `Rig.Kafka.GroupSubscriber`; take a look at its
  moduledoc for more information. Finally, `Rig.Kafka.MessageHandler` hosts the
  code for the actual processing of incoming messages.

  Note that this supervisor is not a classical OTP supervisor: in case one of the
  restart limits is reached, it doesn't simply die, like an OTP supervisor would.
  Instead, it waits for some fixed delay, resets itself and tries again. This enables
  us to stay alive even if the connection to Kafka breaks down, without filling up the
  log files too quickly.

  """
  @behaviour :supervisor3
  use Rig.Config, :custom_validation
  require Logger

  alias RigOutboundGateway.Kafka.GroupSubscriber

  def start_link do
    :supervisor3.start_link(
      _sup_name = {:local, __MODULE__},
      _module = __MODULE__,
      _args = :ok
    )
  end

  @impl :supervisor3
  def init(:ok) do
    conf = config()

    if conf.ssl == nil and conf.sasl != nil do
      Logger.warn("SASL is enabled, but SSL is not - credentials are transmitted as cleartext.")
    end

    add_sasl_option = fn opts ->
      if conf.sasl, do: Keyword.put(opts, :sasl, conf.sasl), else: opts
    end

    client_conf =
      [
        endpoints: conf.brokers,
        auto_start_producers: true,
        default_producer_config: [],
        ssl: conf.ssl
      ]
      |> add_sasl_option.()

    Logger.debug(fn -> format_client_conf(client_conf) end)

    parent_restart_strategy = {:rest_for_one, _max_restarts = 1, _max_time = 10}

    children = [
      child_spec(
        :brod_client,
        :worker,
        [conf.brokers, conf.brod_client_id, client_conf],
        conf.restart_delay_ms
      ),
      child_spec(GroupSubscriber, :worker, [], conf.restart_delay_ms)
    ]

    {:ok, {parent_restart_strategy, children}}
  end

  defp format_client_conf(client_conf) do
    redact_password = fn
      ssl when is_list(ssl) ->
        case ssl[:password] do
          nil -> ssl
          _ -> Keyword.put(ssl, :password, "<REDACTED>")
        end

      no_ssl_config ->
        no_ssl_config
    end

    "Setting up Kafka connection:\n" <>
      (client_conf
       |> Keyword.update(:ssl, nil, redact_password)
       |> inspect(pretty: true))
  end

  @impl :supervisor3
  def post_init(_) do
    :ignore
  end

  # Confex callback
  defp validate_config!(config) do
    ssl_enabled? = config |> Keyword.fetch!(:ssl_enabled?)

    ssl =
      if ssl_enabled? do
        opts = [
          certfile: config |> Keyword.fetch!(:ssl_certfile) |> resolve_path,
          keyfile: config |> Keyword.fetch!(:ssl_keyfile) |> resolve_path,
          cacertfile: config |> Keyword.fetch!(:ssl_ca_certfile) |> resolve_path
        ]

        case Keyword.fetch!(config, :ssl_keyfile_pass) do
          "" -> opts
          pass -> Keyword.put(opts, :password, String.to_charlist(pass))
        end
      else
        false
      end

    %{
      restart_delay_ms: config |> Keyword.fetch!(:restart_delay_ms),
      brod_client_id: config |> Keyword.fetch!(:brod_client_id),
      brokers: config |> Keyword.fetch!(:hosts) |> parse_hosts,
      ssl: ssl,
      sasl: config |> Keyword.fetch!(:sasl) |> parse_sasl_config
    }
  end

  @spec resolve_path(path :: String.t()) :: String.t()
  defp resolve_path(path) do
    working_dir = :code.priv_dir(:rig_outbound_gateway)
    expanded_path = Path.expand(path, working_dir)
    true = File.regular?(expanded_path) || "#{path} is not a file"
    expanded_path
  end

  @spec parse_hosts([String.t(), ...]) :: keyword(pos_integer())
  defp parse_hosts(hosts) do
    hosts
    |> Enum.map(fn broker ->
      [host, port] = String.split(broker, ":")
      {String.to_atom(host), String.to_integer(port)}
    end)
  end

  @spec parse_sasl_config(String.t() | nil) :: nil | {:plain, String.t(), String.t()}
  defp parse_sasl_config(nil), do: nil

  defp parse_sasl_config("plain:" <> plain) do
    [username | rest] = String.split(plain, ":")
    password = rest |> Enum.join(":")
    {:plain, username, password}
  end

  defp child_spec(module, type, args, restart_delay_ms) do
    {
      _id = module,
      _start_func = {
        _mod = module,
        _func = :start_link,
        _args = args
      },
      _restart = {
        _strategy = :permanent,
        _delay_s = div(restart_delay_ms, 1_000)
      },
      # timeout (or :brutal_kill)
      _shutdown = 5000,
      type,
      _modules = [module]
    }
  end
end
