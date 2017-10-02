defmodule Gateway.ApiProxy.Tracker do
  @moduledoc """
  Encapsulates Phoenix Presence, mainly to ease testing.

  """

  # defmodule TrackerBehaviour do
  #   @moduledoc false
  #   @callback track(jti :: String.t, expiry :: Timex.DateTime.t) :: {:ok, String.t}
  #   @callback untrack(jti :: String.t) :: :ok
  #   @callback list() :: [{String.t, %{optional(String.t) => String.t}}]
  #   @callback find(jti :: String.t) :: {String.t, %{optional(String.t) => String.t}} | nil
  # end
  # 
  # require Logger
  @behaviour TrackerBehaviour

  alias Gateway.ApiProxy.PresenceHandler, as: Presence
  # alias Gateway.Blacklist.Serializer

  @topic "proxy"

  @impl TrackerBehaviour
  def track(id, api) do
    IO.puts "TRACK"
    IO.inspect id
    IO.inspect api
    Phoenix.Tracker.track(
      _tracker = Presence,
      _pid = Process.whereis(Gateway.PubSub),
      @topic,
      _key = id,
      _meta = api)
  end
  
  @impl TrackerBehaviour
  def untrack(id) do
    Phoenix.Tracker.untrack(
      _tracker = Presence,
      _pid = Process.whereis(Gateway.PubSub),
      @topic,
      _key = id)
  end

  @impl TrackerBehaviour
  def list do
    Phoenix.Tracker.list(Presence, @topic)
  end

  @impl TrackerBehaviour
  def update(id, api) do
    Phoenix.Tracker.update(
      _tracker = Presence,
      _pid = Process.whereis(Gateway.PubSub),
      @topic,
      _key = id,
      _meta = api)
  end

  @impl TrackerBehaviour
  def find(id) do
    list() |> Enum.find(fn({key, _meta}) -> key == id end)
  end
end
