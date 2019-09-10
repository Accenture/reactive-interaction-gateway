defmodule BlacklistTest do
  @moduledoc """
  Blacklisting a session should terminate active connections and prevent new ones.
  """
  use ExUnit.Case, async: true

  alias RIG.JWT

  @rig_api_url "http://localhost:4010/"

  describe "After blacklisting a session," do
    test "the API reports the session to be blacklisted." do
      session_id = "some random string 90238490829084902342"
      blacklist(session_id)
      assert blacklisted?(session_id)
    end

    test "new connections using the same session are no longer allowed." do
      # blacklist a JWT
      session_id = "some random string 98908462643632748511213123"
      blacklist(session_id)

      # try to connect and verify it doesn't work
      jwt = new_jwt(%{"jti" => session_id})
      assert {:error, %{code: 400}} = SseClient.try_connect_then_disconnect(jwt: jwt)
      assert {:error, _} = WsClient.try_connect_then_disconnect(jwt: jwt)
    end

    test "active connections related to that session are terminated." do
      # Connect to RIG using a JWT:

      session_id = "some random string 8902731973190231212"
      jwt = new_jwt(%{"jti" => session_id})

      assert {:ok, sse} = SseClient.connect(jwt: jwt)
      {_, sse} = SseClient.read_welcome_event(sse)
      {_, sse} = SseClient.read_subscriptions_set_event(sse)

      assert {:ok, ws} = WsClient.connect(jwt: jwt)
      {_, ws} = WsClient.read_welcome_event(ws)
      {_, ws} = WsClient.read_subscriptions_set_event(ws)

      # Create an additional connection using a different JWT:

      other_session_id = "some random string 97123689684290890423312"
      other_jwt = new_jwt(%{"jti" => other_session_id})

      assert {:ok, other_sse} = SseClient.connect(jwt: other_jwt)
      {_, other_sse} = SseClient.read_welcome_event(other_sse)
      {_, other_sse} = SseClient.read_subscriptions_set_event(other_sse)

      # Blacklist only the first JWT using RIG's HTTP API:

      blacklist(session_id)

      # Verify all connections but the last one have been dropped:

      assert {_event, sse} = SseClient.read_event(sse, "rig.session_killed")
      assert {:closed, sse} = SseClient.status(sse)

      assert {:closed, ws} = WsClient.status(ws)

      assert {:ok, other_sse} = SseClient.refute_receive(other_sse)
      assert {:open, other_sse} = SseClient.status(other_sse)
    end
  end

  # ---

  defp blacklist(session_id) do
    body =
      %{validityInSeconds: 60, sessionId: session_id}
      |> Jason.encode!()

    {:ok, %HTTPoison.Response{status_code: 201}} =
      HTTPoison.post("#{@rig_api_url}/v2/session-blacklist", body, [
        {"content-type", "application/json"}
      ])
  end

  # ---

  defp blacklisted?(jti) do
    case HTTPoison.get("#{@rig_api_url}/v2/session-blacklist/#{URI.encode(jti)}") do
      {:ok, %HTTPoison.Response{status_code: 200}} -> true
      {:ok, %HTTPoison.Response{status_code: 404}} -> false
    end
  end

  # ---

  defp new_jwt(claims) do
    JWT.encode(claims)
  end
end
