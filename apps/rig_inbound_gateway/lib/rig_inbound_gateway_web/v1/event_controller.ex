defmodule RigInboundGatewayWeb.V1.EventController do
  @moduledoc """
  Publish a CloudEvent.
  """
  require Logger

  use RigInboundGatewayWeb, :controller

  alias Rig.CloudEvent
  alias Rig.EventHub
  alias RigAuth.AuthorizationCheck.Submission

  @doc "Plug action to send a CloudEvent to subscribers."
  def publish(conn, _params) do
    with {:ok, cloud_event} <- CloudEvent.parse(conn.body_params),
         :ok <- Submission.check_authorization(conn, cloud_event) do
      EventHub.publish(cloud_event)

      conn
      |> put_status(:accepted)
      |> json(cloud_event |> CloudEvent.to_json_map())
    else
      {:error, :not_authorized} ->
        conn |> put_status(:forbidden) |> text("Submission denied.")

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> text("Failed to parse request body: #{inspect(reason)}")
    end
  end
end
