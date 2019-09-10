defmodule RigApi.V2.SessionBlacklistTest do
  @moduledoc false
  use RigApi.ConnCase, async: true

  alias UUID

  @prefix "/v2"

  test "After blacklisting a session ID, the location header points to the blacklist entry." do
    session_id = UUID.uuid4()

    body = Jason.encode!(%{validityInSeconds: 123, sessionId: session_id})

    conn =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> post(@prefix <> "/session-blacklist", body)

    # Assert 201 and json response:
    json_response(conn, 201)

    [entry_location] = get_resp_header(conn, "location")

    # We know it's an absolute-path reference, so we can use build_conn to fetch it.
    build_conn()
    |> get(entry_location)
    |> json_response(200)
  end
end
