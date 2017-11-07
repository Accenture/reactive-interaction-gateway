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
          [] -> config
          _ -> raise "Missing required settings for module #{inspect __ENV__.module}: #{inspect missing_keys}"
        end
      end
    end
  end
end
