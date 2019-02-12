defmodule RigInboundGatewayWeb.V1.SubscriptionController do
  use Rig.Config, [:cors]
  use RigInboundGatewayWeb, :controller

  alias Result

  alias Rig.Connection
  alias RIG.JWT
  alias Rig.Subscription
  alias RIG.Subscriptions
  alias RigAuth.AuthorizationCheck.Subscription, as: SubscriptionAuthZ
  alias RigAuth.Session
  alias RigInboundGateway.Subscriptions, as: RigInboundGatewaySubscriptions

  require Logger

  # ---

  @doc false
  def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> put_resp_header("access-control-allow-methods", "PUT")
    |> put_resp_header("access-control-allow-headers", "content-type,authorization")
    |> send_resp(:no_content, "")
  end

  # ---

  defp with_allow_origin(conn) do
    %{cors: origins} = config()
    put_resp_header(conn, "access-control-allow-origin", origins)
  end

  # ---

  @doc """
  Sets subscriptions for an existing connection, replacing previous subscriptions.

  There may be multiple subscriptions contained in the request body. Each subscription
  refers to a single event type and may optionally include a constraint list
  (conjunctive normal form). Subscriptions that were present in a previous request but
  are no longer present in this one will be removed.

  ## Example

  Single subscription with a constraint that says "either head_repo equals
  `octocat/Hello-World`, or `base_repo` equals `octocat/Hello-World` (or both)":

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
  @spec set_subscriptions(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def set_subscriptions(
        %{method: "PUT", body_params: %{"subscriptions" => subscriptions}} = conn,
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

      jwt_subscription_results =
        conn.req_headers
        |> JWT.parse_http_header()
        |> Result.filter_and_unwrap()
        |> Enum.reduce(%{}, &Map.merge/2)
        |> Subscriptions.from_jwt_claims()

      manual_subscription_results = Enum.map(subscriptions, &Subscription.new/1)

      all_errors =
        Result.filter_and_unwrap_err(jwt_subscription_results) ++
          Result.filter_and_unwrap_err(manual_subscription_results)

      if Enum.empty?(all_errors) do
        all_subscriptions =
          Enum.uniq(
            Result.filter_and_unwrap(jwt_subscription_results) ++
              Result.filter_and_unwrap(manual_subscription_results)
          )

        :ok =
          RigInboundGatewaySubscriptions.check_and_forward_subscriptions(
            socket_pid,
            all_subscriptions
          )

        send_resp(conn, :no_content, "")
      else
        conn |> put_status(:bad_request) |> json(all_errors)
      end
    else
      {:error, :not_authorized} ->
        conn |> put_status(:forbidden) |> text("Subscription denied.")

      {:error, :not_base64} ->
        Logger.warn(fn -> "Connection token #{connection_id} is not Base64 encoded." end)
        conn |> put_status(:bad_request) |> text("Invalid connection token.")

      {:error, :invalid_term} ->
        Logger.warn(fn -> "Connection token #{connection_id} is not a valid term." end)
        conn |> put_status(:bad_request) |> text("Invalid connection token.")

      {:error, :process_dead} ->
        conn |> put_status(:gone) |> text("Connection no longer exists.")

      {:error, :could_not_parse_subscriptions, bad_subscriptions} ->
        conn
        |> put_status(:bad_request)
        |> text("Could not parse subscriptions: #{inspect(bad_subscriptions)}")
    end
  end

  # ---

  defp connection_alive!(pid) do
    if Process.alive?(pid), do: :ok, else: {:error, :process_dead}
  end
end
