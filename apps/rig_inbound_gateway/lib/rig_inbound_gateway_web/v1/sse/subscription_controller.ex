defmodule RigInboundGatewayWeb.V1.SSE.SubscriptionController do
  require Logger
  use RigInboundGatewayWeb, :controller

  alias RigInboundGatewayWeb.V1.SSE.Connection
  alias Rig.EventHub

  @doc """
  Ensures there's a subscription for the given topic.

  If there is no such subscription yet, it will be created. Otherwise, nothing
  happens.

  Note that if your event types happen to include slash characters, you need to escape
  them in the URL using `%2F`. For example:
  `.../subscriptions/my%2Fnon-standard%2Fevent-type`
  """
  @spec set(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def set(conn, %{
        "connection_id" => connection_id,
        "event_type" => event_type
      }) do
    %{body_params: body_params} = conn

    recursive? =
      case Map.get(body_params, "recursive", false) do
        true -> true
        _ -> false
      end

    case Connection.deserialize(connection_id) do
      {:ok, sse_pid} ->
        EventHub.subscribe(sse_pid, event_type, recursive?)

        connection_status = if Process.alive?(sse_pid), do: "alive", else: "dead"

        Logger.debug(fn ->
          "Subscribed #{inspect(sse_pid)} (#{connection_status})" <>
            " to #{event_type} (recursive=#{recursive?})"
        end)

        conn
        |> put_status(:created)
        |> json(%{
          "connection" => connection_status,
          "eventType" => event_type,
          "recursive" => recursive?
        })

      {:error, _} ->
        conn |> put_status(:bad_request) |> text("Invalid connection token.")
    end
  end
end
