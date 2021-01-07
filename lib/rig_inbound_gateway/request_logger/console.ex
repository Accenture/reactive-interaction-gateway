defmodule RigInboundGateway.RequestLogger.Console do
  @moduledoc """
  Example request logger implementation.
  """
  @behaviour RigInboundGateway.RequestLogger

  @impl RigInboundGateway.RequestLogger
  @spec log_call(Proxy.endpoint(), Proxy.api_definition(), %Plug.Conn{}) :: :ok
  def log_call(
        endpoint,
        api_definition,
        _conn
      ) do
    IO.puts("CALL: #{endpoint_desc(endpoint)} => #{api_definition["proxy"]["target_url"]}")
    :ok
  end

  defp endpoint_desc(endpoint) do
    "[#{endpoint["id"]}] #{endpoint["method"]} #{endpoint["path_regex"]}"
  end
end
