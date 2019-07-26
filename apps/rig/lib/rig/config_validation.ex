defmodule RIG.ConfigValidation do
  @moduledoc """
  Module responsible for global validation of environment variables and provides utility
  functions to validate configuration in respective modules.
  """
  use Rig.Config, :custom_validation
  require Logger

  # Confex callback
  defp validate_config!(config) do
    active_loggers = Keyword.fetch!(config, :active_loggers)
    brokers = Keyword.fetch!(config, :brokers)

    if Enum.member?(active_loggers, "kafka") do
      validate_dependent_value("REQUEST_LOG", "kafka", "KAFKA_BROKERS", brokers)
    end

    %{active_loggers: active_loggers, brokers: brokers}
  end

  # ---

  @spec validate_value_difference(String.t(), [String.t(), ...], [String.t(), ...])
   :: :ok | :shutdown
  def validate_value_difference(env_var_name, env_var_value, expected_value) do
    is_empty? =
      MapSet.new(env_var_value)
      |> MapSet.difference(MapSet.new(expected_value))
      |> Enum.empty?()

    if !is_empty? do
      Logger.error(fn ->
        "Invalid configuration for=#{env_var_name} expected=#{inspect(expected_value)} found=#{
          inspect(env_var_value)
        }"
      end)

      exit(:shutdown)
    end

    :ok
  end

  # ---

  @spec validate_dependent_value(String.t(), String.t(), String.t(), [String.t(), ...])
   :: :ok | :shutdown
  def validate_dependent_value(env_var_name, env_var_value, depedency_env_var_name, dependency_env_var_value) do
    is_empty? =
      dependency_env_var_value
      |> Enum.empty?()

    if is_empty? do
      Logger.error(fn ->
        "Configuration for=#{env_var_name} is set to=#{env_var_value}, but required configuration=#{depedency_env_var_name} is empty"
      end)

      exit(:shutdown)
    end

    :ok
  end
end
