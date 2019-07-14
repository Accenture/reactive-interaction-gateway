defmodule RigInboundGatewayWeb.V1.LongpollingController do
  @moduledoc """
  Handling of Longpolling functionalitiy
  """
  require Logger
  use Rig.Config, [:cors]

  use RigInboundGatewayWeb, :controller

  alias Rig.Connection
  alias RigInboundGatewayWeb.Session
  alias RigOutboundGateway

  @doc false
  def handle_connection(%{method: "GET"} = conn, _params) do
    conn = conn |> fetch_cookies

    conn.req_cookies["connection_token"] |> is_new_session? |> process_request(conn)
  end

  # -----
  # Helpers
  # -----

  # validates if a connection_token was given.
  # If yes, it validates if corresponding session processes are still alive
  # ignoring invalid/timed out cookies
  defp is_new_session?(connection_token) do
    case connection_token do
      nil ->
        true

      connection_token ->
        with {:ok, session_pid} <- Connection.Codec.deserialize(connection_token) do
          !Process.alive?(session_pid)
        else
          _ -> false
        end
    end
  end

  # ---
  defp process_request(is_new_session, conn)

  # starts a new session
  defp process_request(true, conn) do
    with {:ok, session_pid} <- Session.start(conn.query_params) do
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
      |> text(Jason.encode!("ok"))
    else
      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> text("PARSE ERROR: #{inspect(message)}; SENT PARAMS: #{inspect(conn.query_params)})")
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
  end
end
