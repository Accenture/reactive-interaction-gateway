defmodule RigInboundGatewayWeb.V1.SSE do
  @moduledoc """
  Server-Sent Events (SSE) handler.
  """
  @behaviour :cowboy_loop

  use Rig.Config, [:cors]

  alias Jason
  alias ServerSentEvent

  alias Result

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent
  alias RigInboundGateway.Events
  alias RigInboundGatewayWeb.ConnectionInit

  require Logger

  @heartbeat_interval_ms 15_000
  @subscription_refresh_interval_ms 60_000

  # ---

  @impl :cowboy_loop
  def init(req, _state) do
    query_params = req |> :cowboy_req.parse_qs() |> Enum.into(%{})
    jwt = query_params["jwt"]

    auth_info =
      case jwt do
        jwt when byte_size(jwt) > 0 ->
          %{auth_header: "Bearer #{jwt}", auth_tokens: [{"bearer", jwt}]}

        _ ->
          nil
      end

    case ConnectionInit.subscriptions_query_param_to_body(query_params) do
      {:ok, encoded_body_or_nil} ->
        request = %{
          auth_info: auth_info,
          query_params: "",
          content_type: "application/json; charset=utf-8",
          body: encoded_body_or_nil
        }

        do_init(req, request)

      {:error, reason} ->
        req = :cowboy_req.reply(400, %{}, reason, req)
        {:stop, req, :unknown_state}
    end
  end

  # ---

  def do_init(req, request) do
    conf = config()

    on_success = fn subscriptions ->
      # Tell the client the request is good and the response is chunked:
      req =
        :cowboy_req.stream_reply(
          200,
          %{
            "content-type" => "text/event-stream; charset=utf-8",
            "cache-control" => "no-cache",
            "access-control-allow-origin" => conf.cors
          },
          req
        )

      # Say hello to the client:
      Events.welcome_event()
      |> to_server_sent_event()
      |> send_via(req)

      # Enter the loop and wait for cloud events to forward to the client:
      state = %{subscriptions: subscriptions}
      {:cowboy_loop, req, state, :hibernate}
    end

    on_error = fn reason ->
      req = :cowboy_req.reply(400, %{}, reason, req)
      {:stop, req, :no_state}
    end

    ConnectionInit.set_up(
      "SSE",
      request,
      on_success,
      on_error,
      @heartbeat_interval_ms,
      @subscription_refresh_interval_ms
    )
  end

  # ---

  @impl :cowboy_loop
  def info(:heartbeat, req, state) do
    # We send a heartbeat now:
    :heartbeat
    |> to_server_sent_event()
    |> send_via(req)

    # And schedule the next one:
    Process.send_after(self(), :heartbeat, @heartbeat_interval_ms)

    {:ok, req, state, :hibernate}
  end

  @impl :cowboy_loop
  def info(%{} = event, req, state) do
    Logger.debug(fn -> "event: " <> inspect(event) end)

    # Forward the event to the client:
    event
    |> to_server_sent_event()
    |> send_via(req)

    {:ok, req, state, :hibernate}
  end

  @impl :cowboy_loop
  def info({:set_subscriptions, subscriptions}, req, state) do
    Logger.debug(fn -> "subscriptions: " <> inspect(subscriptions) end)

    # Trigger immediate refresh:
    EventFilter.refresh_subscriptions(subscriptions, state.subscriptions)

    # Replace current subscriptions:
    state = Map.put(state, :subscriptions, subscriptions)

    # Notify the client:
    Events.subscriptions_set(subscriptions)
    |> to_server_sent_event()
    |> send_via(req)

    {:ok, req, state, :hibernate}
  end

  @impl :cowboy_loop
  def info(:refresh_subscriptions, req, state) do
    EventFilter.refresh_subscriptions(state.subscriptions, [])
    Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)
    {:ok, req, state, :hibernate}
  end

  @impl :cowboy_loop
  def info({:session_killed, session_id}, req, state) do
    Logger.info("Session killed: #{inspect(session_id)} - terminating SSE/#{inspect(self())}..")

    # We tell the client:
    :session_killed
    |> to_server_sent_event()
    |> send_via(req)

    # And close the connection:
    {:stop, req, state}
  end

  # ---

  @impl :cowboy_loop
  def terminate(reason, _req, _state) do
    Logger.debug(fn ->
      pid = inspect(self())
      reason = "reason=" <> inspect(reason)
      "Closing SSE connection (#{pid}, #{reason})"
    end)

    :ok
  end

  # ---

  defp to_server_sent_event(:heartbeat), do: %{comment: "heartbeat"}

  defp to_server_sent_event(:session_killed) do
    %{
      specversion: "0.2",
      type: "rig.session_killed",
      source: "rig",
      id: UUID.uuid4(),
      time: Timex.now() |> Timex.format!("{RFC3339}")
    }
    |> CloudEvent.parse!()
    |> to_server_sent_event()
  end

  defp to_server_sent_event(%CloudEvent{} = event),
    do: %{
      data: event.json,
      event: CloudEvent.type!(event)
    }

  defp to_server_sent_event(%{} = event),
    do: %{
      data: Cloudevents.to_json(event),
      event: CloudEvent.type!(event)
    }

  # ---

  defp send_via(event, cowboy_req) do
    :cowboy_req.stream_events(event, :nofin, cowboy_req)
    Logger.debug(fn -> "Sent via SSE: " <> inspect(event) end)
  end
end
