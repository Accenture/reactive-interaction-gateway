defmodule RigInboundGateway.ApiProxyInjection do
  @moduledoc false

  @mods [RigApi.V1.APIs, RigApi.V2.APIs]
  @orig_vals for mod <- @mods, do: {mod, Application.get_env(:rig, mod)}

  def set do
    for mod <- @mods do
      Application.put_env(:rig, mod,
        rig_proxy: RigInboundGateway.Proxy,
        persistent: true
      )
    end
  end

  def restore do
    for {mod, orig_val} <- @orig_vals do
      Application.put_env(:rig, mod, orig_val, persistent: true)
    end
  end
end
