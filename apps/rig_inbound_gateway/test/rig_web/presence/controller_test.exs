defmodule RigInboundGatewayWeb.Presence.ControllerTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use RigInboundGatewayWeb.ConnCase
  use RigInboundGatewayWeb.ChannelCase

  setup do
    {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      [@customer_role],
      "user:testuser"
    )
   {:ok, sock: sock}
  end

  test "GET /rg/sessions should return list of channels", %{sock: sock} do
    conn =
      setup_conn(["getSessions"])
      |> get("/rg/sessions")

    assert response(conn, 200) =~ "[\"testuser\"]"
    leave sock
  end

  test "GET /rg/sessions/testuser should return list of users in channel testuser", %{sock: sock} do
    conn =
      setup_conn(["getSessionConnections"])
      |> get("/rg/sessions/testuser")

    username =
      json_response(conn, 200)
      |> List.first
      |> Map.get("username")

    assert length(json_response(conn, 200)) == 1
    assert username == "testuser"
    leave sock
  end

  test "DELETE /rg/connections/abc123 should broadcast disconnect event to user with jti abc123", %{sock: sock} do
    @endpoint.subscribe("abc123")
    conn =
      setup_conn(["deleteConnection"])
      |> delete("/rg/connections/abc123")

    assert_broadcast("disconnect", %{})
    assert response(conn, 204) =~ "{}"

    leave sock
    @endpoint.unsubscribe("abc123")
  end
end
