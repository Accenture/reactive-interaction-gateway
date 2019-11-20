defmodule RigInboundGateway.ProxyMock do
  @moduledoc false

  @mock_apis [{"new-service", %{
    "auth" => %{
      "header_name" => "",
      "query_name" => "",
      "use_header" => false,
      "use_query" => false
    },
    "auth_type" => "none",
    "id" => "new-service",
    "name" => "new-service",
    "proxy" => %{"port" => 4444, "target_url" => "API_HOST", "use_env" => true},
    "version_data" => %{"default" => %{"endpoints" => []}},
    "versioned" => false,
    "active" => true
  }}, {"another-service", %{
    "auth" => %{
      "header_name" => "",
      "query_name" => "",
      "use_header" => false,
      "use_query" => false
    },
    "auth_type" => "none",
    "id" => "another-service",
    "name" => "new-service",
    "proxy" => %{"port" => 4444, "target_url" => "API_HOST", "use_env" => true},
    "version_data" => %{"default" => %{"endpoints" => []}},
    "versioned" => false,
    "active" => false
  }}]

  @behaviour RigInboundGateway.Proxy.ProxyBehaviour

  def list_apis(_server) do
    @mock_apis
  end

  def get_api(_server, id) do
    @mock_apis |> Enum.find(fn({api_id, _api}) -> api_id == id end)
  end

  def add_api(_server, id, _api) do
    if get_api(nil, id) do
      :error
    else
      {:ok, "phx_ref"}
    end
  end

  def replace_api(_server, _id, _prev_api, _next_api) do
    {:ok, "phx_ref"}
  end

  def update_api(_server, _id, _api) do
    {:ok, "phx_ref"}
  end

  def deactivate_api(_server, _id) do
    {:ok, "phx_ref"}
  end
end
