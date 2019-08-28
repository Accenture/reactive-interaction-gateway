defmodule RigInboundGateway.ApiProxyInjection do
  @moduledoc false

  @orig_val Application.get_env(:rig, RigApi.ApisController)

  def set do
    Application.put_env(:rig, RigApi.ApisController,
      rig_proxy: RigInboundGateway.Proxy,
      persistent: true
    )
  end

  def restore do
    Application.put_env(:rig, RigApi.ApisController, @orig_val, persistent: true)
  end
end
