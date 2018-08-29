defmodule RigApi.SessionBlacklistController do
  @moduledoc """
  Allows for blocking "sessions" for a specific period of time.

  What a session is depends on your business context and the `JWT_SESSION_FIELD`
  setting. For example, a session ID could be a random ID assigned to a token upon
  login, or the id of the user the token belongs to.

  """
  use RigApi, :controller
  require Logger

  alias RigAuth.Session

  @cors_origins "*"

  @doc false
  def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> put_resp_header("access-control-allow-methods", "POST")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> send_resp(:no_content, "")
  end

  defp with_allow_origin(conn) do
    put_resp_header(conn, "access-control-allow-origin", @cors_origins)
  end

  @doc "Check blacklist status for a specific session id."
  def check_status(%{method: "GET"} = conn, %{"session_id" => session_id}) do
    json(conn, %{
      "sessionId" => session_id,
      "isBlacklisted" => Session.blacklisted?(session_id)
    })
  end

  @doc "Plug action to add a session id to the session blacklist."
  def blacklist_session(%{method: "POST"} = conn, _params) do
    conn = with_allow_origin(conn)

    case parse(conn.body_params) do
      {:error, reason} ->
        send_resp(conn, :bad_request, reason)

      {:ok, %{session_id: session_id, ttl_s: ttl_s}} ->
        Session.blacklist(session_id, ttl_s)

        json(conn, %{
          "sessionId" => session_id,
          "validityInSeconds" => ttl_s,
          "isBlacklisted" => true
        })
    end
  end

  defp parse(body) do
    {:ok,
     %{
       session_id: Map.fetch!(body, "sessionId"),
       ttl_s: body |> Map.fetch!("validityInSeconds") |> String.to_integer()
     }}
  rescue
    e in KeyError ->
      {:error, "Missing value for '#{e.key}'"}

    e in ArgumentError ->
      # This is likely String.to_integer/1, but we don't know for sure.
      {:error, "Invalid request body"}
  end
end
