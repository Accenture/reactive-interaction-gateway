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
  defmodule SyntaxError do
    defexception [:cause]

    def message(%__MODULE__{cause: cause}) when is_list(cause),
      do: "could not parse JSON: #{inspect(cause)}"

    def message(%__MODULE__{cause: cause}) when byte_size(cause) > 0,
      do: "could not parse JSON: #{cause}"

    def message(%__MODULE__{cause: cause}),
      do: "could not parse JSON: #{Exception.message(cause)}"
  end

  require Logger
  alias Jason
  alias Result

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

  # ---

  defp uppercase_http_method(apis) when is_list(apis) do
    Enum.map(apis, fn api ->
      if Map.has_key?(api, "version_data") do
        %{"version_data" => version_data} = api

        updated_version_data =
          Enum.into(version_data, %{}, fn {key, value} = api ->
            endpoints = Map.get(value, "endpoints")

            if is_list(endpoints) do
              updated_endpoints =
                Enum.map(endpoints, fn endpoint ->
                  if Map.has_key?(endpoint, "method") do
                    Map.update!(endpoint, "method", &Plug.Router.Utils.normalize_method/1)
                  else
                    endpoint
                  end
                end)

              {key, Map.update!(value, "endpoints", fn _ -> updated_endpoints end)}
            else
              api
            end
          end)

        Map.update!(api, "version_data", fn _ -> updated_version_data end)
      else
        api
      end
    end)
  end

  defp uppercase_http_method(parsed_json), do: parsed_json

  # ---
  # pub
  # ---

  @spec parse_json_env(String.t()) :: {:ok, any} | {:error, %SyntaxError{}}
  def parse_json_env(path_or_encoded) do
    decode_json_file(path_or_encoded)
    |> Result.or_else(fn file_error ->
      from_encoded(path_or_encoded)
      |> Result.map_err(fn decode_error -> [file_error, decode_error] end)
    end)
    |> Result.map(&uppercase_http_method/1)
    |> Result.map_err(&%SyntaxError{cause: &1})
  end

  # ---

  @spec check_and_update_https_config(Keyword.t()) :: Keyword.t()
  def check_and_update_https_config(config) do
    certfile = resolve_path_or_abort("HTTPS_CERTFILE", config[:https][:certfile])
    keyfile = resolve_path_or_abort("HTTPS_KEYFILE", config[:https][:keyfile])
    password = config[:https][:password] |> String.to_charlist()

    case set_https(config, certfile, keyfile, password) do
      {:ok, {config, :https_enabled}} ->
        Logger.debug(fn ->
          certfile = "certfile=" <> (config |> get_in([:https, :certfile]) |> inspect())
          keyfile = "keyfile=" <> (config |> get_in([:https, :keyfile]) |> inspect())
          "SSL enabled: #{certfile} #{keyfile}"
        end)

        config

      {:ok, {config, :https_disabled}} ->
        Logger.warn(fn ->
          """
          HTTPS is *disabled*. To enable it, set the HTTPS_CERTFILE and HTTPS_KEYFILE environment variables \
          (see https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html for details). \
          Note that we strongly recommend enabling HTTPS (unless you've employed TLS termination elsewhere). \
          """
        end)

        config

      {:error, :only_password} ->
        Logger.error("Please also set HTTPS_CERTFILE and HTTPS_KEYFILE to enable HTTPS.")
        System.stop(1)

      {:error, :only_keyfile} ->
        Logger.error("Please also set HTTPS_CERTFILE to enable HTTPS.")
        System.stop(1)

      {:error, :only_certfile} ->
        Logger.error("Please also set HTTPS_KEYFILE to enable HTTPS.")
        System.stop(1)
    end
  end

  # ----
  # priv
  # ----

  defp set_https(config, certfile, keyfile, password)
  defp set_https(config, :empty, :empty, ''), do: {:ok, {disable_https(config), :https_disabled}}
  defp set_https(_, :empty, :empty, _), do: {:error, :only_password}
  defp set_https(_, :empty, _, _), do: {:error, :only_keyfile}
  defp set_https(_, _, :empty, _), do: {:error, :only_certfile}

  defp set_https(config, certfile, keyfile, password),
    do: {:ok, {enable_https(config, certfile, keyfile, password), :https_enabled}}

  # ---

  defp enable_https(config, certfile, keyfile, password),
    do:
      config
      |> put_in([:https, :certfile], certfile)
      |> put_in([:https, :keyfile], keyfile)
      |> put_in([:https, :password], password)

  # ---

  defp disable_https(config), do: put_in(config, [:https], false)

  # ---

  @spec decode_json_file(String.t()) :: {:ok, any} | {:error, reason :: any}
  defp decode_json_file(path) do
    path
    |> resolve_path()
    |> case do
      {:error, err} ->
        {:error, err}

      {:ok, path} ->
        with {:ok, content} <- File.read(path),
             {:ok, config} <- from_encoded(content) do
          {:ok, config}
        else
          {:error, _reason} = err -> err
        end
    end
  end

  # ---

  defp resolve_path_or_abort(var_name, value) do
    case resolve_path(value) do
      {:ok, path} ->
        path

      {:error, :empty} ->
        :empty

      {:error, {:not_found, path}} ->
        Logger.error("Could not resolve #{var_name}: #{inspect(path)}")
        # Under normal circumstances this stops the VM:
        System.stop(1)
        # When running in mix test, the code will simply continue, which leads to
        # strange errors down the road :( Instead, we're gonna wait for the log message
        # to print out and then forcefully stop the world.
        :timer.sleep(1_000)
        System.halt(1)
    end
  end

  # ---

  defp resolve_path(path)
  defp resolve_path(nil), do: {:error, :empty}
  defp resolve_path(""), do: {:error, :empty}

  defp resolve_path(path) do
    %{found?: false, path: path}
    |> check_path_as_is()
    |> check_relative_to_priv()
    |> case do
      %{found?: false} -> Result.err({:not_found, path})
      %{path: path} -> Result.ok(path)
    end
  end

  # ---

  defp check_path_as_is(%{found?: false, path: path} = ctx) when byte_size(path) > 0,
    do: if(File.exists?(path), do: %{ctx | found?: true}, else: ctx)

  defp check_path_as_is(ctx), do: ctx

  # ---

  defp check_relative_to_priv(%{found?: false, path: path} = ctx) when byte_size(path) > 0 do
    priv_dir()
    |> Result.map(fn priv_dir ->
      path = Path.join(priv_dir, path)

      if File.exists?(path) do
        %{found?: true, path: path}
      else
        ctx
      end
    end)
    # If the app is not yet loaded this errors, so let's ignore that:
    |> Result.unwrap_or(ctx)
  end

  defp check_relative_to_priv(ctx), do: ctx

  # ---

  defp priv_dir do
    case :code.priv_dir(:rig) do
      {:error, _} = err -> err
      priv_dir -> {:ok, priv_dir}
    end
  end

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
end
