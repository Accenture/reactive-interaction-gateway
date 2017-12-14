defmodule RigInboundGateway.Blacklist.Tracker do
  @moduledoc """
  Encapsulates Phoenix Presence, mainly to ease testing.

  """

  defmodule TrackerBehaviour do
    @moduledoc false
    @callback track(jti :: String.t, expiry :: Timex.DateTime.t) :: {:ok, String.t}
    @callback untrack(jti :: String.t) :: :ok
    @callback list() :: [{String.t, %{optional(String.t) => String.t}}]
    @callback find(jti :: String.t) :: {String.t, %{optional(String.t) => String.t}} | nil
  end

  require Logger
  @behaviour TrackerBehaviour

  alias RigInboundGateway.Blacklist.PresenceHandler, as: Presence
  alias RigInboundGateway.Blacklist.Serializer

  @topic "blacklist"

  @impl TrackerBehaviour
  def track(jti, expiry) do
    Phoenix.Tracker.track(
      _tracker = Presence,
      _pid = Process.whereis(RigMesh.PubSub),
      @topic,
      _key = jti,
      _meta = %{expiry: Serializer.serialize_datetime!(expiry)})
  end

  @impl TrackerBehaviour
  def untrack(jti) do
    Phoenix.Tracker.untrack(
      _tracker = Presence,
      _pid = Process.whereis(RigMesh.PubSub),
      @topic,
      _key = jti)
  end

  @impl TrackerBehaviour
  def list do
    Phoenix.Tracker.list(Presence, @topic)
  end

  @impl TrackerBehaviour
  def find(jti) do
    list() |> Enum.find(fn({key, _meta}) -> key == jti end)
  end
end
