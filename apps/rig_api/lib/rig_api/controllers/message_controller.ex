defmodule RigApi.MessageController do
  require Logger

  use RigApi, :controller

  alias RigOutboundGateway

  action_fallback RigApi.FallbackController

  @doc """
  Accepts message to be sent to front-ends.

  Note that `message` is _always_ a map. For example:

  - Given '"foo"', the `:json` parser will pass '{"_json": "foo"}'.
  - Given 'foo', the `:urlencoded` parser will pass '{"foo": nil}'.
  """
  def create(conn, message) do
    with :ok <- RigOutboundGateway.send(message) do
      send_resp(conn, :accepted, "message queued for transport")
    else
      {:error, %KeyError{key: key, term: term}} ->
        send_resp(conn, :bad_request, ~s(Bad request: expected user-ID in field "#{key}", got "#{inspect term}".\nPlease make sure the Content-Type is set correctly and that you actually pass a map.\n))

      err ->
        err |> inspect |> Logger.warn
        send_resp(conn, :bad_request, "Bad request")
    end
  end
end
