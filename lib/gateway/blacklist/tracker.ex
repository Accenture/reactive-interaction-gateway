defmodule Gateway.Blacklist.Tracker do
  defmodule TrackerBehaviour do
    @callback track(jti: String.t, expiry: Timex.DateTime.t) :: {:ok, String.t}
    @callback untrack(jti: String.t) :: :ok
    @callback list() :: [{String.t, %{optional(String.t) => String.t}}]
    @callback find(jti: String.t) :: {String.t, %{optional(String.t) => String.t}} | nil
  end

  require Logger
  @behaviour TrackerBehaviour

  alias Gateway.Blacklist.PresenceHandler, as: Presence
  alias Gateway.Blacklist.Serializer

  @topic "blacklist"

  @spec track(String.t, Timex.DateTime.t) :: {:ok, String.t}
  def track(jti, expiry) do
    Phoenix.Tracker.track(
      _tracker=Presence,
      _pid=Process.whereis(Gateway.PubSub),
      @topic,
      _key=jti,
      _meta=%{expiry: Serializer.serialize_datetime!(expiry)})
  end

  @spec untrack(String.t) :: :ok
  def untrack(jti) do
    Phoenix.Tracker.untrack(
      _tracker=Presence,
      _pid=Process.whereis(Gateway.PubSub),
      @topic,
      _key=jti)
  end

  @spec list() :: [{String.t, %{optional(String.t) => String.t}}]
  def list do
    Phoenix.Tracker.list(Presence, @topic)
  end

  @spec find(String.t) :: {String.t, %{optional(String.t) => String.t}} | nil
  def find(jti) do
    list() |> Enum.find(fn {key, _meta} -> key == jti end)
  end
end
