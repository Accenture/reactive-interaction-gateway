defmodule RigInboundGateway.ApiProxy.Handler do
  @moduledoc """
  Request handler that proxies the request according to the implementation.
  """
  alias Plug.Conn

  alias RigInboundGateway.ApiProxy.Api

  @callback handle_http_request(Conn.t(), Api.t(), Api.endpoint()) :: :ok | {:error, any}
end
