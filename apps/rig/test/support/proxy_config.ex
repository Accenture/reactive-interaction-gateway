defmodule RigInboundGateway.ProxyConfig do
  @moduledoc false

  @var_name "PROXY_CONFIG_FILE"
  @orig_val System.get_env(@var_name)

  def set(apis) when is_list(apis) do
    System.put_env(@var_name, Jason.encode!(apis))
  end

  def restore do
    case @orig_val do
      nil -> System.delete_env(@var_name)
      _ -> System.put_env(@var_name, @orig_val)
    end
  end
end
