defmodule RigInboundGateway.EnvVars do
  @moduledoc false

  def set(name, value) do
    orig_value = System.get_env(name)
    System.put_env(name, value)
    orig_value
  end

  # ---

  def restore(name, orig_value) do
    case orig_value do
      nil -> System.delete_env(name)
      _ -> System.put_env(name, orig_value)
    end
  end
end
