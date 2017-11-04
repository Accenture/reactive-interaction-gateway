defmodule Gateway.Config do
  @moduledoc """
  Gateway module configuration that provides `settings/0`.

  There are two ways to use this module

  ### Specify a list of expected keys

  ```
  defmodule Gateway.MyExample do
    use Gateway.Config, [:some_key, :other_key]
  end
  ```

  `Gateway.Config` expects a config entry similar to this:
  ```
  config :gateway, Gateway.MyExample,
    some_key: ...,
    other_key: ...
  ```
  If one of the specified keys is not found, an error is thrown _at compile time_.
  Otherwise, `Gateway.MyExample` gets a `config/0` function that returns the
  configuration converted to a map.
  If there are other keys present, they'll be added to that map as well.

  ### Specify `:custom_validation` instead

  ```
  defmodule Gateway.MyExample do
    use Gateway.Config, :custom_validation

    defp validate_config!(config) do
      ...
    end
  end
  ```
  If you use :custom_validation, you should deal with the raw keyword list
  by implementing `validate_config!/1` in the module.
  """

  defmacro __using__(:custom_validation) do
    Gateway.Config.__everything_but_validation__()
  end
  defmacro __using__(required_keys) do
    quote do
      unquote(Gateway.Config.__everything_but_validation__())
      unquote(Gateway.Config.__only_validation__(required_keys))
    end
  end

  def __everything_but_validation__ do
    quote do
      use Confex, otp_app: :gateway

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
          [] -> config
          _ -> raise "Missing required settings for module #{inspect __ENV__.module}: #{inspect missing_keys}"
        end
      end
    end
  end
end
