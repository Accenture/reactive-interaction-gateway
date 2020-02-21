defmodule RigInboundGateway.SystemMock do
  @moduledoc false

  def stop() do
    Process.exit(self(), :ReverseProxyConfigurationError)
  end
end
