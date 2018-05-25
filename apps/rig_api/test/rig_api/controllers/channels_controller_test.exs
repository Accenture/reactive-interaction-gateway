defmodule RigApi.ChannelsControllerTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use RigApi.ChannelCase
  use RigApi.ConnCase

  @endpoint_channels RigInboundGatewayWeb.Endpoint

  setup do
    {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      [@customer_role],
      "user:testuser"
    )
   {:ok, sock: sock}
  end

  test "GET /v1/users should return list of channels", %{sock: sock} do
    conn =
      build_conn()
      |> get("/v1/users")
    assert response(conn, 200) =~ "[\"testuser\"]"
    leave sock
  end

  test "GET /v1/users/testuser/sessions should return list of users in channel testuser", %{sock: sock} do
    conn =
      build_conn()
      |> get("/v1/users/testuser/sessions")

    username =
      json_response(conn, 200)
      |> List.first
      |> Map.get("username")

    assert length(json_response(conn, 200)) == 1
    assert username == "testuser"
    leave sock
  end

  test "DELETE /v1/sessions/abc123 should broadcast disconnect event to user with jti abc123", %{sock: sock} do
    @endpoint_channels.subscribe("abc123")
    conn =
      build_conn()
      |> delete("/v1/sessions/abc123")

    assert_broadcast("disconnect", %{})
    assert response(conn, 204) =~ "{}"

    leave sock
    @endpoint_channels.unsubscribe("abc123")
  end
end
