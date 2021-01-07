defmodule RigInboundGatewayWeb.V1.LongpollingController do
  @moduledoc """
  Handling of Longpolling functionalitiy
  """
  require Logger
  use Rig.Config, [:cors]

  use RigInboundGatewayWeb, :controller

  alias Rig.Connection
  alias RigInboundGatewayWeb.ConnectionLimit
  alias RigInboundGatewayWeb.Session
  alias RigOutboundGateway

  # ---

  @doc false
  def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> put_resp_header("access-control-allow-methods", "GET")
    |> put_resp_header("access-control-allow-headers", "*")
    |> send_resp(:no_content, "")
  end

  # ---

  @doc false
  def handle_connection(%{method: "GET"} = conn, _params) do
    conn = conn |> fetch_cookies |> fetch_query_params
    conn.req_cookies["connection_token"] |> is_new_session? |> process_request(conn)
  end

  # -----
  # Helpers
  # -----

  # validates if a connection_token was given.
  # If yes, it validates if corresponding session processes are still alive
  # ignoring invalid/timed out cookies
  defp is_new_session?(connection_token)
  defp is_new_session?(nil), do: true

  defp is_new_session?(connection_token) do
    case Connection.Codec.deserialize(connection_token) do
      {:ok, session_pid} -> !Process.alive?(session_pid)
      _ -> false
    end
  end

  # ---

  defp process_request(is_new_session, conn)

  # starts a new session
  defp process_request(true, conn) do
    with {:ok, _n_connections} <- ConnectionLimit.check_rate_limit(),
         {:ok, session_pid} <- Session.start(conn.query_params) do
      Logger.debug(fn ->
        "new Longpolling connection (pid=#{inspect(session_pid)}, params=#{
          inspect(conn.query_params)
        })"
      end)

      conn
      |> with_allow_origin()
      |> put_resp_cookie("connection_token", session_pid |> Connection.Codec.serialize())
      |> put_resp_cookie("last_event_id", Jason.encode!("first_event"))
      |> put_resp_header("content-type", "application/json; charset=utf-8")
      |> put_resp_header("cache-control", "no-cache")
      |> put_status(200)
      |> text("ok")
    else
      {:error, {:bad_request, message}} ->
        conn
        |> with_allow_origin()
        |> put_status(:bad_request)
        |> text(message)

      {:error, %ConnectionLimit.MaxConnectionsError{n_connections: n_connections} = ex} ->
        Logger.warn(fn ->
          pid = inspect(self())
          msg = "#{Exception.message(ex)}=#{n_connections} per minute"
          "Cannot accept long polling connection #{pid}: #{msg}"
        end)

        conn
        |> put_status(:too_many_requests)
        |> text(Exception.message(ex))

      error ->
        msg = "Failed to initialize long polling connection"
        Logger.error(fn -> "#{msg}: #{inspect(error)}" end)

        conn
        |> with_allow_origin()
        |> put_status(:internal_server_error)
        |> text("Internal server error: #{msg}.")
    end
  end

  # reconnect to existing session
  defp process_request(false, conn) do
    {:ok, session_pid} = Connection.Codec.deserialize(conn.req_cookies["connection_token"])

    response =
      Session.recv_events(
        session_pid,
        Jason.decode!(conn.req_cookies["last_event_id"] || "first_event")
      )

    conn
    |> with_allow_origin()
    |> put_resp_cookie("connection_token", session_pid |> Connection.Codec.serialize())
    |> put_resp_cookie("last_event_id", Jason.encode!(response[:last_event_id] || "first_event"))
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> put_resp_header("cache-control", "no-cache")
    |> put_status(200)
    |> text(
      ~s<{"last_event_id":"#{response.last_event_id}","events":[#{Enum.join(response.events, ",")}]}>
    )
  end

  # ---
  defp with_allow_origin(conn) do
    %{cors: origins} = config()

    put_resp_header(conn, "access-control-allow-origin", origins)
    |> put_resp_header("access-control-allow-credentials", "true")
  end
end
