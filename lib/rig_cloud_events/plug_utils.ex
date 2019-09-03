defmodule RigCloudEvents.PlugUtils do
  @moduledoc """
  Common code for dealing with CloudEvents in controllers.

  The CloudEvents specification defines how CloudEvents must be accepted depending on
  the transport; see [HTTP Transport Binding for CloudEvents].

  We _deviate_ a bit from the spec by interpreting requests as using structured mode
  if they come with content type `application/json` and without a `ce-specversion`
  header. See `RigCloudEvents.PlugUtils.cloudevents_mode/1` for details.

  [HTTP Transport Binding for CloudEvents]: https://github.com/cloudevents/spec/blob/master/http-transport-binding.md
  """
  alias Plug.Conn

  require Logger

  # ---

  def handle_cloudevent(conn, handlers \\ []) do
    mode = cloudevents_mode(conn)
    do_handle_cloudevent(conn, handlers, mode)
  end

  # ---

  def do_handle_cloudevent(conn, handlers, mode) do
    Logger.debug(fn -> "Received CloudEvent in #{mode} mode" end)
    handler = handlers[mode]

    if is_nil(handler),
      do: Conn.send_resp(conn, :unsupported_media_type, not_implemented_message(mode)),
      else: handler.(conn)
  end

  # ---

  defp not_implemented_message(mode),
    do: """
    The #{mode} CloudEvents HTTP transport binding mode is currently not supported.
    """

  # ---

  defp cloudevents_mode(conn) do
    content_type = content_type(conn)

    # The content type is the primary criterion.
    case content_type do
      {"application", "cloudevents-batch"} ->
        :batched

      {"application", "cloudevents+" <> _} ->
        :structured

      {"application", "json"} ->
        # According to the spec this should be :binary. But we fall back to :structured
        # in case the specversion header is not present. People will send us
        # CloudEvents, which are JSONs by default, as JSONs, that is, with content type
        # "application/json". To some people this seems intuitive and we try to be nice
        # here. Also, with the specversion header not present, it's not proper :binary
        # anyway.
        if Conn.get_req_header(conn, "ce-specversion") == [] do
          # ce-specversion header not present, so we assume structured.
          :structured
        else
          # The body is the JSON encoded data field.
          :binary
        end

      _ ->
        # Fallback according to the spec:
        :binary
    end
  end

  # ---

  defp content_type(conn) do
    [as_string] = Conn.get_req_header(conn, "content-type")
    {:ok, type, subtype, _params} = Conn.Utils.content_type(as_string)
    {type, subtype}
  end
end
