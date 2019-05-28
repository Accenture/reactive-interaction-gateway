defmodule RigInboundGatewayWeb.V1.LongpollingController do
  @moduledoc """
  Handling of Longpolling functionalitiy
  """
  require Logger
  use Rig.Config, [:cors]

  use RigInboundGatewayWeb, :controller

  alias RigOutboundGateway
  alias RigInboundGatewayWeb.Session
  alias Rig.Connection

  @doc false
  def handle_connection(%{method: "GET"} = conn, _params) do
    conn = conn |> fetch_cookies

    is_new_session =
      if conn.req_cookies["connection_token"] === nil do
        true
      else
        {:ok, session_pid} = Connection.Codec.deserialize(conn.req_cookies["connection_token"])
        !Process.alive?(session_pid)
      end

    # No session set -> start new session
    if(is_new_session) do
      with {:ok, session_pid} <- Session.start(conn.query_params) do
        Logger.debug(fn ->
          "new Longpolling connection (pid=#{inspect(session_pid)}, params=#{
            inspect(conn.query_params)
          })"
        end)

        conn
        |> with_allow_origin()
        |> put_resp_cookie("connection_token", session_pid |> Connection.Codec.serialize())
        |> put_resp_cookie("last_event_id", Jason.encode!(0))
        |> put_resp_header("content-type", "application/json; charset=utf-8")
        |> put_resp_header("cache-control", "no-cache")
        |> send_resp(200, Jason.encode!("ok"))
      else
        {:error, message} ->
          conn
          |> send_resp(
            400,
            "PARSE ERROR: #{inspect(message)}; SENT PARAMS: #{inspect(conn.query_params)})"
          )
      end
    else
      # reconnect to existing session
      {:ok, session_pid} = Connection.Codec.deserialize(conn.req_cookies["connection_token"])

      response =
        Session.recv_events(session_pid, Jason.decode!(conn.req_cookies["last_event_id"] || "0"))

      conn
      |> with_allow_origin()
      |> put_resp_cookie("connection_token", session_pid |> Connection.Codec.serialize())
      |> put_resp_cookie("last_event_id", Jason.encode!(response[:last_event_id] || 0))
      |> put_resp_header("content-type", "application/json; charset=utf-8")
      |> put_resp_header("cache-control", "no-cache")
      |> send_resp(
        200,
        ~s<{"last_event_id":"#{response.last_event_id}","events":[#{
          Enum.join(response.events, ",")
        }]}>
      )
    end
  end

  # -----
  # Helpers
  # -----

  defp with_allow_origin(conn) do
    %{cors: origins} = config()
    put_resp_header(conn, "access-control-allow-origin", origins)
  end
end
