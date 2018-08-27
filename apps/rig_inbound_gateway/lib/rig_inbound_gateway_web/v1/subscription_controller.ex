defmodule RigInboundGatewayWeb.V1.SubscriptionController do
  require Logger
  use Rig.Config, [:cors]
  use RigInboundGatewayWeb, :controller

  alias Rig.EventHub
  alias RigAuth.Session
  alias RigAuth.AuthorizationCheck.Subscription
  alias RigInboundGateway.Connection

  @doc false
  def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> put_resp_header("access-control-allow-methods", "PUT")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> send_resp(:no_content, "")
  end

  defp with_allow_origin(conn) do
    %{cors: origins} = config()
    put_resp_header(conn, "access-control-allow-origin", origins)
  end

  @doc """
  Ensures there's a subscription for the given topic.

  If there is no such subscription yet, it will be created.

  Note that if your event types happen to include slash characters, you need to escape
  them in the URL using `%2F`. For example:
  `.../subscriptions/my%2Fnon-standard%2Fevent-type`
  """
  @spec set(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def set(%{method: "PUT"} = conn, %{
        "connection_id" => connection_id,
        "event_type" => event_type
      }) do
    conn = with_allow_origin(conn)

    %{body_params: body_params} = conn

    recursive? =
      case Map.get(body_params, "recursive") do
        true -> true
        _ -> false
      end

    with :ok <- Subscription.check_authorization(conn, event_type, recursive?),
         {:ok, sse_pid} <- Connection.deserialize(connection_id),
         :ok <- connection_alive!(sse_pid) do
      # Updating the session allows blacklisting it later on:
      Session.update(conn, sse_pid)

      EventHub.subscribe(sse_pid, event_type, recursive?)

      Logger.debug(fn ->
        "Subscribed #{inspect(sse_pid)} to #{event_type} (recursive=#{recursive?})"
      end)

      conn
      |> put_status(:created)
      |> json(%{
        "eventType" => event_type,
        "recursive" => recursive?
      })
    else
      {:error, :not_authorized} ->
        conn |> put_status(:forbidden) |> text("Subscription denied.")

      {:error, :not_base64} ->
        conn |> put_status(:bad_request) |> text("Invalid connection token.")

      {:error, :invalid_term} ->
        conn |> put_status(:bad_request) |> text("Invalid connection token.")

      {:error, :process_dead} ->
        conn |> put_status(:gone) |> text("Connection no longer exists.")
    end
  end

  defp connection_alive!(pid) do
    if Process.alive?(pid), do: :ok, else: {:error, :process_dead}
  end
end
