defmodule Gateway.Blacklist do
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
  require Logger
  alias Gateway.Blacklist.Serializer

  @default_tracker_mod Gateway.Blacklist.Tracker
  @default_expiry_hours :gateway
  |> Application.fetch_env!(Gateway.Endpoint)
  |> Keyword.get(:jwt_blacklist_default_expiry_hours)

  def start_link(tracker_mod \\ nil, opts \\ []) do
    tracker_mod = if tracker_mod, do: tracker_mod, else: @default_tracker_mod
    Logger.debug "Blacklist with tracker #{inspect tracker_mod}"
    GenServer.start_link(
      __MODULE__,
      _state = %{tracker_mod: tracker_mod},
      Keyword.merge([name: __MODULE__], opts))
  end

  def add_jti(server, jti, expiry \\ nil, listener \\ nil)
  def add_jti(server, jti, _expiry = nil, listener) do
    default_expiry = Timex.now() |> Timex.shift(hours: @default_expiry_hours)
    add_jti(server, jti, default_expiry, listener)
  end
  def add_jti(server, jti, expiry, listener) do
    expires_at =
      case Timex.is_valid? expiry do
        {:error, :invalid_date} -> Serializer.deserialize_datetime!(expiry)
        true -> expiry
        # else fail
      end
    GenServer.cast(server, {:add, jti, expires_at, listener})
    server  # allow for chaining calls
  end

  def contains_jti?(server, jti) do
    GenServer.call(server, {:contains?, jti})
  end

  # callbacks

  def init(state) do
    send(self(), :expire_stale_records)
    {:ok, state}
  end

  def handle_cast({:add, jti, expiry, listener}, state) do
    with {:ok, _phx_ref} <- state.tracker_mod.track(jti, expiry) do
      remaining_ms = max(
        (Timex.diff(expiry, Timex.now(), :seconds) + 1) * 1_000,
        0
      )
      Process.send_after(self(), {:expire, jti, listener}, _timeout = remaining_ms)
    end
    {:noreply, state}
  end

  def handle_call({:contains?, jti}, _from, state) do
    contains? = case state.tracker_mod.find(jti) do
      {_jti, _meta} -> true
      nil -> false
    end
    {:reply, contains?, state}
  end

  def handle_info({:expire, jti, listener}, state) do
    Logger.debug "JTI #{jti} expired"
    expire(state.tracker_mod, jti)
    if listener, do: send_expiration_notification(listener, jti)
    {:noreply, state}
  end

  def handle_info(:expire_stale_records, state) do
    now = Timex.now()
    state.tracker_mod.list()
    |> Stream.filter(fn {_jti, meta} -> meta.expiry |> Timex.before?(now) end)
    |> Enum.each(fn {jti, _meta} -> state.tracker_mod.untrack(jti) end)
    {:noreply, state}
  end

  # private functions

  defp expire(tracker_mod, jti) do
    tracker_mod.untrack(jti)
  end

  defp send_expiration_notification(listener, jti) do
    send(listener, {:expired, jti})
    Logger.debug "notified #{inspect listener} about expiration of JTI #{inspect jti}"
  end
end
