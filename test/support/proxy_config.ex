defmodule RigInboundGateway.ProxyConfig do
  @moduledoc false

  @var_name "PROXY_CONFIG_FILE"
  @orig_val System.get_env(@var_name)

  def set(apis) when is_list(apis) do
    System.put_env(@var_name, Jason.encode!(apis))
  end

  def set(name, value) do
    orig_value = System.get_env(name)
    System.put_env(name, value)
    orig_value
  end

  def restore_one(name, orig_value) do
    case orig_value do
      nil -> System.delete_env(name)
      _ -> System.put_env(name, orig_value)
    end
  end

  def restore do
    case @orig_val do
      nil -> System.delete_env(@var_name)
      _ -> System.put_env(@var_name, @orig_val)
    end
  end
end
