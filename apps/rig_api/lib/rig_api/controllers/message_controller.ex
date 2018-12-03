defmodule RigApi.MessageController do
  require Logger

  use RigApi, :controller

  alias Rig.CloudEvent

  action_fallback(RigApi.FallbackController)

  @event_filter Application.get_env(:rig, :event_filter)

  @doc """
  Accepts message to be sent to front-ends.

  Note that `message` is _always_ a map. For example:

  - Given '"foo"', the `:json` parser will pass '{"_json": "foo"}'.
  - Given 'foo', the `:urlencoded` parser will pass '{"foo": nil}'.
  """
  def create(conn, message) do
    with {:ok, cloud_event} <- CloudEvent.new(message) do
      @event_filter.forward_event(cloud_event)

      send_resp(conn, :accepted, "message queued for transport")
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> text("Failed to parse request body: #{inspect(reason)}")
    end
  end
end
