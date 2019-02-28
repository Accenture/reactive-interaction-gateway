defmodule Rig.Config do
  @moduledoc """
  Rig module configuration that provides `settings/0`.

  There are two ways to use this module

  ### Specify a list of expected keys

  ```
  defmodule Rig.MyExample do
    use Rig.Config, [:some_key, :other_key]
  end
  ```

  `Rig.Config` expects a config entry similar to this:
  ```
  config :rig, Rig.MyExample,
    some_key: ...,
    other_key: ...
  ```
  If one of the specified keys is not found, an error is thrown _at compile time_.
  Otherwise, `Rig.MyExample` gets a `config/0` function that returns the
  configuration converted to a map.
  If there are other keys present, they'll be added to that map as well.

  ### Specify `:custom_validation` instead

  ```
  defmodule Rig.MyExample do
    use Rig.Config, :custom_validation

    defp validate_config!(config) do
      ...
    end
  end
  ```
  If you use :custom_validation, you should deal with the raw keyword list
  by implementing `validate_config!/1` in the module.
  """
  require Logger
  alias Jason

  defmacro __using__(:custom_validation) do
    __MODULE__.__everything_but_validation__()
  end

  defmacro __using__(required_keys) do
    quote do
      unquote(__MODULE__.__everything_but_validation__())
      unquote(__MODULE__.__only_validation__(required_keys))
    end
  end

  def __everything_but_validation__ do
    quote do
      use Confex, otp_app: :rig

      @after_compile __MODULE__

      def __after_compile__(env, _bytecode) do
        # Make sure missing configuration values are caught early by evaluating the values here
        env.module.config()
      end
    end
  end

  def __only_validation__(required_keys) do
    quote do
      defp validate_config!(nil), do: validate_config!([])

      defp validate_config!(config) do
        # Convert to map and make sure all required keys are present
        config = Enum.into(config, %{})

        required_keys = unquote(required_keys)
        missing_keys = for k <- required_keys, not Map.has_key?(config, k), do: k

        case missing_keys do
          [] ->
            config

          _ ->
            raise "Missing required settings for module #{inspect(__ENV__.module)}: #{
                    inspect(missing_keys)
                  }"
        end
      end
    end
  end

  # -------------
  # Public Interface
  # -------------

  @spec parse_json_env(String.t()) :: {:ok, any} | {:error, :syntax_error, any}
  def parse_json_env(path_or_encoded) do
    with {:error, reason1} <- from_file(path_or_encoded),
         {:error, reason2} <- from_encoded(path_or_encoded) do
      {:error, :syntax_error, [reason1, reason2]}
    else
      {:ok, config} -> {:ok, config}
    end
  end

  # ---

  @spec check_and_update_https_config(Keyword.t()) :: Keyword.t()
  def check_and_update_https_config(config) do
    certfile = config[:https][:certfile]

    if(certfile === "") do
      Logger.warn("No HTTPS_CERTFILE environment variable provided. Disabling HTTPS...")

      # DISABLE HTTPS
      config
      |> update_in([:https], &disable_https/1)
    else
      # UPDATE https_config to add priv/ folder to path
      config
      |> update_in([:https, :certfile], &resolve_path/1)
      |> update_in([:https, :keyfile], &resolve_path/1)
      |> update_in([:https, :password], &String.to_charlist/1)
    end
  end

  # -------------
  # Helpers
  # -------------

  @spec from_file(String.t()) :: {:ok, any} | {:error, reason :: any}
  defp from_file(path) do
    %{path: path, found?: false}
    |> check_path_as_is()
    |> check_relative_to_priv()
    |> case do
      %{found?: false} ->
        {:error, :no_such_file}

      %{path: path} ->
        with {:ok, content} <- File.read(path),
             {:ok, config} <- from_encoded(content) do
          {:ok, config}
        else
          {:error, _reason} = err -> err
        end
    end
  end

  # ---

  defp check_path_as_is(%{found?: false, path: path} = ctx) when byte_size(path) > 0,
    do: if(File.exists?(path), do: %{ctx | found?: true}, else: ctx)

  defp check_path_as_is(ctx), do: ctx

  # ---

  defp check_relative_to_priv(%{found?: false, path: path} = ctx) when byte_size(path) > 0 do
    phx_app_list()
    |> Enum.map(fn app -> :code.priv_dir(app) |> Path.join(path) end)
    |> Enum.find(&File.exists?/1)
    |> case do
      nil -> ctx
      path -> %{found?: true, path: path}
    end
  end

  defp check_relative_to_priv(ctx), do: ctx

  # ---

  @spec from_encoded(String.t()) :: {:ok, any} | {:error, Jason.DecodeError.t() | any}
  defp from_encoded(encoded) when byte_size(encoded) > 0 do
    Jason.decode(encoded)
  end

  defp from_encoded(_), do: {:error, :not_a_nonempty_string}

  # ---

  @spec parse_socket_list([String.t(), ...]) :: [{String.t(), pos_integer()}, ...]
  def parse_socket_list(socket_list) do
    socket_list
    |> Enum.map(fn broker ->
      [host, port] = for part <- String.split(broker, ":"), do: String.trim(part)
      {host, String.to_integer(port)}
    end)
  end

  # ---

  defp resolve_path(path) do
    :code.priv_dir(:rig) |> Path.join(path)
  end

  # ---

  defp disable_https(_) do
    false
  end

  # ---
  defp phx_app_list do
    [:rig, :rig_inbound_gateway, :rig_api]
  end
end
