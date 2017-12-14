defmodule RigInboundGateway.ApiProxy.Tracker do
  @moduledoc """
  Encapsulates Phoenix Presence, mainly to ease testing.

  """

  defmodule TrackerBehaviour do
    @moduledoc false
    @callback track(id :: String.t, api :: Proxy.api_definition) :: {:ok, String.t}
    @callback update(id :: String.t, api :: Proxy.api_definition) :: {:ok, String.t}
    @callback list_all() :: [{String.t, Proxy.api_definition}]
    @callback list_by_node(node_name :: atom) :: [{String.t, Proxy.api_definition}]
    @callback find_all(id :: String.t) :: [{String.t, Proxy.api_definition}]
    @callback find_by_node(id :: String.t, node_name :: atom) :: {String.t, Proxy.api_definition}
  end

  @behaviour TrackerBehaviour

  require Logger

  alias RigInboundGateway.ApiProxy.PresenceHandler, as: Presence

  @topic "proxy"

  @impl TrackerBehaviour
  def track(id, api) do
    Logger.info("Starting to track new API definition with id=#{id}")
    Phoenix.Tracker.track(
      _tracker = Presence,
      _pid = Process.whereis(RigMesh.PubSub),
      @topic,
      _key = id,
      _meta = api)
  end

  @impl TrackerBehaviour
  def update(id, api) do
    Logger.info("Updating API definition with id=#{id}")
    Phoenix.Tracker.update(
      _tracker = Presence,
      _pid = Process.whereis(RigMesh.PubSub),
      @topic,
      _key = id,
      _meta = api)
  end

  @impl TrackerBehaviour
  def list_all do
    Phoenix.Tracker.list(Presence, @topic)
  end

  @impl TrackerBehaviour
  def list_by_node(node_name) do
    Presence
    |> Phoenix.Tracker.list(@topic)
    |> Enum.filter(fn({_key, meta}) -> meta["node_name"] == node_name end)
  end

  @impl TrackerBehaviour
  def find_all(id) do
    list_all() |> Enum.filter(fn({key, _meta}) -> key == id end)
  end

  @impl TrackerBehaviour
  def find_by_node(id, node_name) do
    list_by_node(node_name) |> Enum.find(fn({key, _meta}) -> key == id end)
  end
end
