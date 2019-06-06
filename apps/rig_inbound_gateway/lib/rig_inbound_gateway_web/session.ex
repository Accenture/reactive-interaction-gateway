defmodule RigInboundGatewayWeb.Session do
  @moduledoc """
  Maintains subscriptions and buffers incoming events.

  Started by, or connected from, a (longpolling) connection process.
  """
  use GenServer

  require Logger

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent
  alias RigInboundGatewayWeb.EventBuffer
  alias RIG.Subscriptions
  alias RigInboundGateway.Events

  @window_size_ms 500
  @max_tries 10
  @event_buffer_size 200
  @subscription_refresh_interval_ms 60_000
  @session_timeout_validation_interval_ms 60_000
  @session_timout_ms 3_600_000

  # ---
  def start(query_params, opts \\ []) do
    GenServer.start(__MODULE__, %{query_params: query_params}, opts)
  end

  def recv_events(server, last_event_id) do
    GenServer.call(server, {:recv_events, last_event_id || "first_event", 0}, 20_000)
  end

  # ---

  # Server Callbacks

  @impl true
  def init(%{query_params: query_params}) do
    # Init Subscriptions: Setup sulbscriptions for the token & also provided as query parameter
    with {:ok, jwt_subs} <- Subscriptions.from_token(query_params["jwt"]),
         {:ok, query_subs} <-
           Map.get(query_params, "subscriptions") |> Subscriptions.from_json() do
      subscriptions = Enum.uniq(jwt_subs ++ query_subs)

      # We initially provide a welcome event...
      send(self(), :welcome_event)
      # ...register subscriptions...
      send(self(), {:set_subscriptions, subscriptions})
      # ..and schedule periodic refresh:
      Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)

      # Init Session Timeout Validation:
      Process.send_after(
        self(),
        :validate_session_timeout,
        @session_timeout_validation_interval_ms
      )

      {:ok,
       %{
         subscriptions: [],
         event_buffer: EventBuffer.new(@event_buffer_size),
         session_valid_until: DateTime.add(DateTime.utc_now(), @session_timout_ms, :millisecond)
       }}
    else
      {:error, %Subscriptions.Error{} = e} ->
        {:stop, Exception.message(e)}
    end
  end

  # ---
  # Waits for events and replies them if available
  @impl true
  def handle_call({:recv_events, last_event_id, _}, from, state) do
    state = %{
      state
      | session_valid_until: DateTime.add(DateTime.utc_now(), @session_timout_ms, :millisecond)
    }

    case EventBuffer.events_since(state.event_buffer, last_event_id) do
      {:ok, [events: [], last_event_id: last_event_id]} ->
        # There are no events, so we let the client wait @window_size_ms and check again:
        Process.send_after(
          self(),
          {:recv_events, from, last_event_id, 1},
          @window_size_ms
        )

        {:noreply, state}

      {:ok, [events: events, last_event_id: last_event_id]} ->
        {:reply,
         %{
           last_event_id: last_event_id,
           events: Enum.map(events, fn x -> x.json end),
           status: :ok
         }, state}

      {:no_such_event, [not_found_id: _not_found_id, last_event_id: last_event_id]} ->
        # the event_id provided by the client was outdated - we send the newest event id
        {:reply, %{last_event_id: last_event_id, events: [], status: :no_such_event}, state}
    end
  end

  # Waits for events and replies them if available (same as above, but as handle_info)
  @impl true
  def handle_info({:recv_events, from, last_event_id, tries}, state) do
    case EventBuffer.events_since(state.event_buffer, last_event_id) do
      {:ok, [events: [], last_event_id: last_event_id]} ->
        case tries do
          @max_tries ->
            # in case we reached the max tries, we send an empty list
            GenServer.reply(from, %{
              last_event_id: last_event_id,
              events: [],
              status: :no_events
            })

            {:noreply, state}

          _ ->
            # There are no events, so we let the client wait @window_size_ms and check again:
            Process.send_after(
              self(),
              {:recv_events, from, last_event_id, tries + 1},
              @window_size_ms
            )

            {:noreply, state}
        end

      {:ok, [events: events, last_event_id: last_event_id]} ->
        # There are events, so we return all available events
        GenServer.reply(from, %{
          last_event_id: last_event_id,
          events: Enum.map(events, fn x -> x.json end),
          status: :ok
        })

        {:noreply, state}

      {:no_such_event, [not_found_id: _not_found_id, last_event_id: last_event_id]} ->
        # the event_id provided by the client was outdated - we send the newest event id
        GenServer.reply(from, %{
          last_event_id: last_event_id,
          events: [],
          status: :no_such_event
        })

        {:noreply, state}
    end
  end

  # ---
  # Accepts a CloudEvent which will be added to the event buffer
  @impl true
  def handle_info(%CloudEvent{} = event, state) do
    Logger.debug(fn -> "event: " <> inspect(event) end)
    event_buffer = state.event_buffer |> EventBuffer.add_event(event)
    {:noreply, %{state | event_buffer: event_buffer}}
  end

  # ---
  # Initially sets the subscriptions 
  @impl true
  def handle_info(:welcome_event, state) do
    # write the event to the event_buffer
    event = Events.welcome_event(self())
    event_buffer = state.event_buffer |> EventBuffer.add_event(event)

    {:noreply, %{state | event_buffer: event_buffer}}
  end

  # ---
  # Initially sets the subscriptions 
  @impl true
  def handle_info({:set_subscriptions, subscriptions}, state) do
    Logger.debug(fn -> "subscriptions: " <> inspect(subscriptions) end)

    # Trigger immediate refresh
    EventFilter.refresh_subscriptions(subscriptions, state.subscriptions)

    # write the event to the event_buffer
    event = Events.subscriptions_set(subscriptions)
    event_buffer = state.event_buffer |> EventBuffer.add_event(event)

    {:noreply, %{state | event_buffer: event_buffer, subscriptions: subscriptions}}
  end

  # ---
  # Periodically refeshes subscriptions
  @impl true
  def handle_info(:refresh_subscriptions, state) do
    EventFilter.refresh_subscriptions(state.subscriptions, [])

    # Schedule next refresh
    Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)

    {:noreply, state}
  end

  # ---
  # Validates if the session is timed out -> Killed if yes
  @impl true
  def handle_info(:validate_session_timeout, state) do
    is_timed_out =
      DateTime.compare(
        state.session_valid_until,
        DateTime.utc_now()
      ) === :lt

    if(is_timed_out) do
      # kills the session process
      {:stop, :normal, state}
    else
      # Schedule next validation interval
      Process.send_after(
        self(),
        :validate_session_timeout,
        @session_timeout_validation_interval_ms
      )

      {:noreply, state}
    end
  end
end
