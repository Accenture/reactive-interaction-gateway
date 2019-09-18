defmodule RigApi.V1.SessionBlacklistTest do
  @moduledoc false
  use RigApi.ConnCase, async: true

  alias UUID

  @prefix "/v1"

  test "After blacklisting a session ID, the blacklist entry is present." do
    session_id = UUID.uuid4()

    body = Jason.encode!(%{validityInSeconds: "123", sessionId: session_id})

    build_conn()
    |> put_req_header("content-type", "application/json")
    |> post(@prefix <> "/session-blacklist", body)
    |> json_response(200)

    build_conn()
    |> get(@prefix <> "/session-blacklist/#{session_id}")
    |> json_response(200)
  end
end
