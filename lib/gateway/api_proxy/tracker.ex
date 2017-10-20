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
  def list_all do
    Phoenix.Tracker.list(Presence, @topic)
  end

  def list_by_node(node_name) do
    Presence
    |> Phoenix.Tracker.list(@topic)
    |> Enum.filter(fn({_key, meta}) -> meta["node_name"] == node_name end)
  end

  def find_all(id) do
    list_all() |> Enum.filter(fn({key, _meta}) -> key == id end)
  end

  def find_by_node(id, node_name) do
    list_by_node(node_name) |> Enum.find(fn({key, _meta}) -> key == id end)
  end
end
