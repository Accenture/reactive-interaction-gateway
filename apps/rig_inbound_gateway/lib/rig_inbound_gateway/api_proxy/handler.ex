defmodule RigInboundGateway.ApiProxy.Handler do
  @moduledoc """
  Request handler that proxies the request according to the implementation.
  """
  alias Plug.Conn

  alias RigInboundGateway.ApiProxy.Api

  @type request_path :: String.t()
  @callback handle_http_request(Conn.t(), Api.t(), Api.endpoint(), request_path) ::
              :ok | {:error, any}
end
