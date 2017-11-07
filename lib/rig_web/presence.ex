defmodule RigWeb.Presence do
  @moduledoc """
  Enables Phoenix Presence.

  """
  use Phoenix.Presence,
    otp_app: :rig,
    pubsub_server: Rig.PubSub
end
