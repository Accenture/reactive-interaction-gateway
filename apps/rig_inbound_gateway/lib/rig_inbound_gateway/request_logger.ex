defmodule RigInboundGateway.RequestLogger do

  @callback log_call(Proxy.endpoint, Proxy.api_definition, %Plug.Conn{}) :: :ok
end
