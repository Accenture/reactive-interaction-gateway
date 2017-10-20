defmodule Gateway.ApiProxy.Tracker do
  @moduledoc """
  Encapsulates Phoenix Presence, mainly to ease testing.

  """

  defmodule TrackerBehaviour do
    @moduledoc false
    @callback track(id :: String.t, api :: map) :: {:ok, String.t}
    @callback untrack(id :: String.t) :: :ok
    @callback list() :: [{String.t, %{optional(String.t) => String.t}}]
  end

  @behaviour TrackerBehaviour

  require Logger

  alias Gateway.ApiProxy.PresenceHandler, as: Presence

  @topic "proxy"

  @impl TrackerBehaviour
  def track(id, api) do
    Logger.info("Started tracking for new API definition with id=#{id}")
    Phoenix.Tracker.track(
      _tracker = Presence,
      _pid = Process.whereis(Gateway.PubSub),
      @topic,
      _key = id,
      _meta = api)
  end

  def update(id, api) do
    Logger.info("Updated API definition with id=#{id}")
    Phoenix.Tracker.update(
      _tracker = Presence,
      _pid = Process.whereis(Gateway.PubSub),
      @topic,
      _key = id,
      _meta = api)
  end

  @impl TrackerBehaviour
  def untrack(id) do
    Logger.info("Untracked API definition with id=#{id}")
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

  def find(id, node_name) do
    list() |> Enum.find(fn({key, meta}) -> key == id && meta["node_name"] == node_name end)
  end
  def find_all(id) do
    list() |> Enum.filter(fn({key, _meta}) -> key == id end)
  end
end
