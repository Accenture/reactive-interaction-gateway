defmodule Gateway.Config do
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