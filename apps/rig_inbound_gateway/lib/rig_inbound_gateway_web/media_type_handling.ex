defmodule RigInboundGatewayWeb.MediaTypeHandling do
  @moduledoc """
  Helper functions around media type handling.
  """

  @spec accept_only_req_for(Plug.Conn.t(), [String.t()]) :: Plug.Conn.t()
  def accept_only_req_for(conn, supported_media_types) do
    if accepts_media_type?(conn, supported_media_types) do
      conn
    else
      passed_headers_info =
        for val <- Plug.Conn.get_req_header(conn, "accept"),
            into: "",
            do: "  Accept: #{val}\n"

      supported_media_types_info = for type <- supported_media_types, into: "", do: "  #{type}\n"

      message = """
      Request headers:
      #{passed_headers_info}
      The following media types are supported by this endpoint:
      #{supported_media_types_info}
      """

      conn
      |> Plug.Conn.send_resp(:not_acceptable, message)
      |> Plug.Conn.halt()
    end
  end

  @type media_type :: {String.t(), String.t()}

  @spec media_type(String.t()) :: media_type
  def media_type(media_type_string) do
    {:ok, type, subtype, _params} = Plug.Conn.Utils.media_type(media_type_string)
    {type, subtype}
  end

  def extract_from_header(conn, header_key, transform) do
    for header_val <- Plug.Conn.get_req_header(conn, header_key),
        token <- String.split(header_val, ","),
        do: transform.(token)
  end

  @spec accepted_media_types(Plug.Conn.t()) :: [media_type]
  def accepted_media_types(conn) do
    case extract_from_header(conn, "accept", &media_type/1) do
      # "*/*" is the default in case the header is not set (according to MDN).
      [] -> [{"*", "*"}]
      media_types -> media_types
    end
  end

  @spec accepts_media_type?(Plug.Conn.t(), [String.t()]) :: Plug.Conn.t()
  def accepts_media_type?(conn, supported_media_types) do
    expected_types = Enum.map(supported_media_types, &media_type/1)
    passed_types = accepted_media_types(conn)

    Enum.reduce_while(passed_types, false, fn
      :error, false ->
        {:cont, false}

      {"*", "*"}, false ->
        {:halt, true}

      media_type, false ->
        if media_type in expected_types do
          {:halt, true}
        else
          {:cont, false}
        end
    end)
  end

  def content_type(conn) do
    [as_string] = Plug.Conn.get_req_header(conn, "content-type")
    {:ok, type, subtype, _params} = Plug.Conn.Utils.content_type(as_string)
    {type, subtype}
  end
end
