defmodule RigInboundGateway.RequestLogger do
  @moduledoc """
  Interface for request logging backends.
  """

  @callback log_call(Proxy.endpoint, Proxy.api_definition, %Plug.Conn{}) :: :ok
end
