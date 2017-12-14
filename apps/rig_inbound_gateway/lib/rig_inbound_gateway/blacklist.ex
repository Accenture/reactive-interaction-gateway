defmodule RigInboundGateway.Blacklist do
  @moduledoc """
  Enables blacklisting of JWTs by their jti claim.

  The entries representing the banned claims feature an expiration timestamp,
  which prevents the blacklist from growing indefinitely.

  In a distributed setting, the node that does the blacklisting spreads the
  information via Phoenix' PubSub Server as Phoenix Presence information. The
  other nodes react by tracking the same record themselves, which means that
  for one record and n nodes there are n items in the Presence list. The
  following properties are a result of this:

  - Blacklisting can occur on/by any node.
  - The blacklist is eventually consistent over all nodes.
  - Any node can go down and come up at any time without affecting the
    blacklist, except if all nodes go down at the same time (in that case
    there is nothing to synchronize from -- the list is not stored on disk).

  """
  use Rig.Config, [:default_expiry_hours]
  require Logger
  alias RigInboundGateway.Blacklist.Serializer

  @typep state_t :: map

  @default_tracker_mod RigInboundGateway.Blacklist.Tracker

  def start_link(tracker_mod \\ nil, opts \\ []) do
    tracker_mod = if tracker_mod, do: tracker_mod, else: @default_tracker_mod
    Logger.debug(fn -> "Blacklist with tracker #{inspect tracker_mod}" end)
    GenServer.start_link(
      __MODULE__,
      _state = %{tracker_mod: tracker_mod},
      Keyword.merge([name: __MODULE__], opts))
  end

  @spec add_jti(pid | atom, String.t, nil | String.t | Timex.DateTime.t, nil | pid) :: pid
  def add_jti(server, jti, expiry \\ nil, listener \\ nil)
  def add_jti(server, jti, _expiry = nil, listener) do
    conf = config()
    default_expiry = Timex.now() |> Timex.shift(hours: conf.default_expiry_hours)
    add_jti(server, jti, default_expiry, listener)
  end
  def add_jti(server, jti, expiry, listener) do
    expires_at =
      case Timex.is_valid? expiry do
        true -> expiry
        _ -> Serializer.deserialize_datetime!(expiry)
      end
    GenServer.cast(server, {:add, jti, expires_at, listener})
    server  # allow for chaining calls
  end

  @spec contains_jti?(pid, String.t) :: boolean
  def contains_jti?(server, jti) do
    GenServer.call(server, {:contains?, jti})
  end

  # callbacks

  @spec init(state_t) :: {:ok, state_t}
  def init(state) do
    send(self(), :expire_stale_records)
    {:ok, state}
  end

  @spec handle_cast({:add, String.t, Timex.DateTime.t, nil | pid}, state_t) :: {:noreply, state_t}
  def handle_cast({:add, jti, expiry, listener}, state) do
    Logger.info("Blacklisting JWT with jti=#{jti}")
    with {:ok, _phx_ref} <- state.tracker_mod.track(jti, expiry) do
      remaining_ms = max(
        (Timex.diff(expiry, Timex.now(), :seconds) + 1) * 1_000,
        0
      )
      Process.send_after(self(), {:expire, jti, listener}, _timeout = remaining_ms)
    end
    {:noreply, state}
  end

  @spec handle_call({:contains?, String.t}, any, state_t) :: {:reply, boolean, state_t}
  def handle_call({:contains?, jti}, _from, state) do
    contains? = case state.tracker_mod.find(jti) do
      {_jti, _meta} -> true
      nil -> false
    end
    {:reply, contains?, state}
  end

  @spec handle_info({:expire, String.t, nil | pid}, state_t) :: {:noreply, state_t}
  def handle_info({:expire, jti, listener}, state) do
    expire(state.tracker_mod, jti, listener)
    {:noreply, state}
  end

  @spec handle_info(:expire_stale_records, state_t) :: {:noreply, state_t}
  def handle_info(:expire_stale_records, state) do
    now = Timex.now()
    state.tracker_mod.list()
    |> Stream.filter(fn({_jti, meta}) -> meta.expiry |> Timex.before?(now) end)
    |> Enum.each(fn({jti, _meta}) -> expire(state.tracker_mod, jti) end)
    {:noreply, state}
  end

  # private functions

  @spec expire(atom, String.t, nil | pid) :: any
  defp expire(tracker_mod, jti, listener \\ nil) do
    Logger.info("Removing JWT with jti=#{jti} from blacklist (entry expired)")
    tracker_mod.untrack(jti)
    if listener, do: send_expiration_notification(listener, jti)
  end

  @spec send_expiration_notification(pid, String.t) :: any
  defp send_expiration_notification(listener, jti) do
    send(listener, {:expired, jti})
    Logger.debug(fn -> "notified #{inspect listener} about expiration of JTI #{inspect jti}" end)
  end
end
