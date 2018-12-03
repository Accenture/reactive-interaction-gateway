defmodule RigOutboundGateway.Kinesis.JavaClient do
  @moduledoc """
  Manages the external Java-based Kinesis client application.

  In Java land this would've been named AmazonKinesisJavaClientManager.
  """
  use Rig.Config, :custom_validation
  use GenServer
  require Logger

  alias Rig.EventFilter
  alias RigOutboundGateway.Kinesis.LogStream

  @jinterface_version "1.8.1"
  @restart_delay_ms 20_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  # Confex callback
  defp validate_config!(config) do
    # checking that the files actually exists is deferred to init (see check_paths/0),
    # as System.cwd doesn't point to the umbrella root at this point.
    otp_jar =
      case Keyword.get(config, :otp_jar) do
        nil ->
          Path.join(:code.root_dir(), "lib/jinterface-#{@jinterface_version}/priv/OtpErlang.jar")

        val ->
          val
      end

    %{
      enabled?: Keyword.fetch!(config, :enabled?),
      client_jar: Keyword.fetch!(config, :client_jar),
      otp_jar: otp_jar,
      log_level: Keyword.fetch!(config, :log_level) || "",
      kinesis_app_name: Keyword.fetch!(config, :kinesis_app_name),
      kinesis_aws_region: Keyword.fetch!(config, :kinesis_aws_region),
      kinesis_stream: Keyword.fetch!(config, :kinesis_stream),
      kinesis_endpoint: Keyword.fetch!(config, :kinesis_endpoint),
      dynamodb_endpoint: Keyword.fetch!(config, :dynamodb_endpoint)
    }
  end

  @impl GenServer
  def init(:ok) do
    conf = config()

    if conf.enabled? do
      # make sure the JInterface Jar file exists:
      true =
        File.exists?(conf.otp_jar) ||
          "Could not find OtpErlang.jar for JInterface #{@jinterface_version} at #{conf.otp_jar}. Does your Erlang distribution come with Java support enabled?"

      send(self(), :run_java_client)
    end

    {:ok, %{}}
  end

  @doc """
  Starts (and awaits) the Java-client for Amazon Kinesis.

  The process output is discarded. Instead of using stdout to receive Kinesis messages
  from the Java client, the Java code uses JInterface to RPC
  RigOutboundGateway.handle_raw/1 directly. This ensures that message boundaries are
  kept (think newlines in messages) and that console log output doesn't interfere.
  """
  @impl GenServer
  def handle_info(:run_java_client, state) do
    conf = config()
    Logger.debug(fn -> "Starting Java-client for Kinesis.." end)

    env = [
      RIG_ERLANG_NAME: :erlang.node() |> Atom.to_string(),
      RIG_ERLANG_COOKIE: :erlang.get_cookie() |> Atom.to_string(),
      LOG_LEVEL: conf.log_level,
      KINESIS_APP_NAME: conf.kinesis_app_name,
      KINESIS_AWS_REGION: conf.kinesis_aws_region,
      KINESIS_STREAM: conf.kinesis_stream,
      KINESIS_ENDPOINT: conf.kinesis_endpoint,
      KINESIS_DYNAMODB_ENDPOINT: conf.dynamodb_endpoint
    ]

    # LogStream is used to pipe the Java logging output to RIG's logging output.
    %Porcelain.Result{status: status} =
      Porcelain.exec("java", java_args(), out: %LogStream{}, err: :out, env: env)

    Logger.warn(fn ->
      "Java-client for Kinesis is dead (exit code #{status}; restart in #{@restart_delay_ms} ms)."
    end)

    Process.send_after(self(), :run_java_client, @restart_delay_ms)

    {:noreply, state}
  end

  defp java_args do
    conf = config()

    args = [
      "-Djava.util.logging.SimpleFormatter.format=%4$s: %5$s%n",
      "-Dexecutor=Elixir.RigOutboundGateway.Kinesis.JavaClient",
      "-Dclient_name=kinesis-client",
      "-cp",
      "#{conf.client_jar}:#{conf.otp_jar}",
      "com.accenture.rig.App"
    ]

    Logger.info(fn -> "Exec: java #{Enum.join(args, " ")}" end)
    args
  end

  @spec java_client_callback(data :: [{atom(), String.t()}, ...]) :: :ok
  def java_client_callback(data) do
    data[:body]
    |> Poison.decode!()
    |> EventFilter.forward_event()

    :ok
  end
end
