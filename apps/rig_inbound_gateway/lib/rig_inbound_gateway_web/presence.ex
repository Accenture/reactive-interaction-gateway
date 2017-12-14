defmodule RigInboundGatewayWeb.Presence do
  @moduledoc """
  Enables Phoenix Presence.

  """
  use Phoenix.Presence,
    otp_app: :rig_inbound_gateway,
    pubsub_server: RigMesh.PubSub
end
