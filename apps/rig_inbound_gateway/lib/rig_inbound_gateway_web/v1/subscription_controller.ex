defmodule RigInboundGatewayWeb.V1.SubscriptionController do
  require Logger
  use Rig.Config, [:cors]
  use RigInboundGatewayWeb, :controller

  alias Rig.Connection
  alias Rig.Subscription
  alias RigAuth.AuthorizationCheck.Subscription, as: SubscriptionAuthZ
  alias RigAuth.Session
  alias RigInboundGateway.ImplicitSubscriptions.Jwt, as: JwtSubscriptions
  alias RigInboundGateway.Subscriptions

  @doc false
  def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> put_resp_header("access-control-allow-methods", "POST")
    |> put_resp_header("access-control-allow-headers", "content-type,authorization")
    |> send_resp(:no_content, "")
  end

  defp with_allow_origin(conn) do
    %{cors: origins} = config()
    put_resp_header(conn, "access-control-allow-origin", origins)
  end

  @doc """
  Adds subscriptions to an existing connection.

  There may be multiple subscriptions contained in the request body. Each subscription
  refers to a single event type and may optionally include a constraint list
  (conjunctive normal form).

  For example, setting up a single subscription with a constraint that says "either
  head_repo equals `octocat/Hello-World`, or `base_repo` equals `octocat/Hello-World`
  (or both)":

      {
        "subscriptions": [
          {
            "eventType": "com.github.pull.create",
            "oneOf": [
              { "head_repo": "octocat/Hello-World" },
              { "base_repo": "octocat/Hello-World" }
            ]
          }
        ]
      }
  """
  @spec create_subscription(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def create_subscription(
        %{method: "POST", body_params: %{"subscriptions" => subscriptions}} = conn,
        %{
          "connection_id" => connection_id
        }
      )
      when is_list(subscriptions) do
    conn = with_allow_origin(conn)

    with :ok <- SubscriptionAuthZ.check_authorization(conn),
         {:ok, socket_pid} <- Connection.Codec.deserialize(connection_id),
         :ok <- connection_alive!(socket_pid) do
      # Updating the session allows blacklisting it later on:
      Session.update(conn, socket_pid)

      jwts = Plug.Conn.get_req_header(conn, "authorization")
      all_subscriptions = subscriptions ++ JwtSubscriptions.check_subscriptions(jwts)

      n_subscriptions =
        Subscriptions.create_subscriptions(socket_pid, all_subscriptions)
        |> Enum.count()

      send_resp(conn, :created, "Subscriptions created: #{n_subscriptions}")
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

  # defp create_subscriptions(socket_pid, subscriptions) do
  #   log_parse_error = fn reason, params ->
  #     Logger.warn(fn ->
  #       params = Jason.encode!(params)
  #       "Error creating subscription for #{socket_pid}: #{reason} (params: #{params})"
  #     end)
  #   end

  #   subscribe = fn
  #     %Subscription{} = sub ->
  #       :ok = Connection.Api.register_subscription(socket_pid, sub)
  #       sub

  #     {:error, reason, params} ->
  #       log_parse_error.(reason, params)
  #   end

  #   subscriptions
  #   |> Enum.map(&Subscription.new/1)
  #   |> Enum.map(subscribe)
  # end
end
