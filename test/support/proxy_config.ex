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

  # ---

  def restore do
    case @orig_val do
      nil -> System.delete_env(@var_name)
      _ -> System.put_env(@var_name, @orig_val)
    end
  end

  def restore(name, orig_value) do
    case orig_value do
      nil -> System.delete_env(name)
      _ -> System.put_env(name, orig_value)
    end
  end

  # ---

  def create_proxy_config(id, endpoints, auth \\ %{}, auth_type \\ nil) do
    %{
      "active" => true,
      "id" => id,
      "name" => id,
      "proxy" => %{
        "port" => 3000,
        "target_url" => "http://localhost",
        "use_env" => false
      },
      "version_data" => %{
        "default" => %{
          "endpoints" => endpoints
        }
      },
      "versioned" => false,
      "auth" => auth,
      "auth_type" => auth_type
    }
  end

  # ---

  def set_proxy_config(id, endpoints, auth \\ %{}, auth_type \\ nil) do
    set([create_proxy_config(id, endpoints, auth, auth_type)])
  end

  def set_proxy_config(proxy) do
    set([proxy])
  end

  def set_proxy_config() do
    set([%{}])
  end
end
