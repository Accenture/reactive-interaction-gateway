defmodule GatewayWeb.Presence do
  @moduledoc """
  Enables Phoenix Presence.

  """
  use Phoenix.Presence,
    otp_app: :gateway,
    pubsub_server: Gateway.PubSub
end