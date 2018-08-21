defmodule RigInboundGatewayWeb.V1.EventController do
  @moduledoc """
  Publish a CloudEvent.
  """
  require Logger

  use RigInboundGatewayWeb, :controller

  alias Rig.CloudEvent
  alias Rig.EventHub

  @doc "Plug action to send a CloudEvent to subscribers."
  def publish(conn, _params) do
    case CloudEvent.parse(conn.body_params) do
      {:ok, cloud_event} ->
        EventHub.publish(cloud_event)

        conn
        |> put_status(:accepted)
        |> json(cloud_event |> CloudEvent.to_json_map())

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> text("Failed to parse request body: #{inspect(reason)}")
    end
  end
end
