defmodule RigInboundGatewayWeb.V1.SubscriptionController do
  use Rig.Config, [:cors]
  use RigInboundGatewayWeb, :controller
  use RigInboundGatewayWeb.Cors, :cors
  use RigInboundGatewayWeb.Cors, :preflight_put

  alias Result

  alias RIG.AuthorizationCheck.Request
  alias RIG.AuthorizationCheck.Subscription, as: SubscriptionAuthZ
  alias Rig.Connection
  alias RIG.JWT
  alias RIG.Plug.BodyReader
  alias RIG.Session
  alias Rig.Subscription
  alias RIG.Subscriptions

  require Logger

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
        %{method: "PUT"} = conn,
        %{
          "connection_id" => connection_id
        }
      ) do
    conn
    |> with_allow_origin()
    |> accept_only_req_for(["application/json"])
    |> Plug.Conn.fetch_query_params()
    |> decode_json_body()
    |> do_set_subscriptions(connection_id)
  end

  # ---

  defp decode_json_body(%{halted: true} = conn), do: conn

  defp decode_json_body(conn) do
    with {"application", "json"} <- content_type(conn),
         {:ok, body, conn} <- BodyReader.read_full_body(conn),
         {:ok, json} <- Jason.decode(body),
         {:parse, %{"subscriptions" => subscriptions}} <- {:parse, json} do
      conn
      |> Plug.Conn.assign(:body, body)
      |> Plug.Conn.assign(:subscriptions, subscriptions)
    else
      {:parse, json} ->
        message = """
        Expected field "subscriptions" is not present.

        Decoded request body:
        #{inspect(json)}
        """

        conn
        |> send_resp(:bad_request, message)
        |> Plug.Conn.halt()

      error ->
        message = """
        Expected JSON encoded body.

        Technical info:
        #{inspect(error)}
        """

        conn
        |> send_resp(:bad_request, message)
        |> Plug.Conn.halt()
    end
  end

  # ---

  defp do_set_subscriptions(%{halted: true} = conn, _connection_id), do: conn

  defp do_set_subscriptions(
         %{assigns: %{subscriptions: subscriptions}} = conn,
         connection_id
       ) do
    request = Request.from_plug_conn(conn)

    with :ok <- SubscriptionAuthZ.check_authorization(request),
         {:ok, socket_pid} <- Connection.Codec.deserialize(connection_id),
         :ok <- check_connection_alive(socket_pid) do
      # If the JWT is valid and points to a session, we associate this connection with
      # it. If that doesn't work out, we log a warning but don't tell the frontend -
      # it's not the frontend's fault anyway.
      refresh_associated_sessions(socket_pid, Map.get(conn.assigns, :auth_tokens, []))
      |> Result.or_else(fn {:failed_to_associate_to_session, errors} ->
        Logger.warn(fn ->
          "failed to associate to session: " <> inspect(for error <- errors, do: inspect(error))
        end)
      end)

      do_set_subscriptions(conn, socket_pid, subscriptions)
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

  defp refresh_associated_sessions(socket_pid, auth_tokens) do
    auth_tokens
    # Extract the JWT claims from bearer tokens and ignore any other tokens:
    |> Enum.map(fn
      {"bearer", token} -> JWT.parse_token(token)
      _ -> {:ok, %{}}
    end)
    |> Result.list_to_result()
    |> Result.map_err(fn decode_errors -> {:failed_to_associate_to_session, decode_errors} end)
    # Infer the session name from each token:
    |> Result.and_then(fn list_of_claims ->
      list_of_claims
      |> Enum.map(&Session.from_claims/1)
      |> Result.list_to_result()
      |> Result.map_err(fn reasons -> {:failed_to_associate_to_session, reasons} end)
    end)
    # Register the connection process to each session:
    |> Result.map(fn session_names ->
      Enum.each(session_names, &Session.register_connection(&1, socket_pid))
    end)
  end

  # ---

  defp do_set_subscriptions(conn, socket_pid, subscriptions_param) do
    with {:ok, jwt_subscriptions} <-
           conn.req_headers
           |> get_all_claims()
           |> Result.and_then(fn claims -> Subscriptions.from_jwt_claims(claims) end),
         {:ok, passed_subscriptions} <- parse_subscriptions(subscriptions_param) do
      subscriptions = jwt_subscriptions ++ passed_subscriptions
      send(socket_pid, {:set_subscriptions, subscriptions})
      send_resp(conn, :no_content, "")
    else
      {:error, error} when byte_size(error) > 0 ->
        conn
        |> put_status(:bad_request)
        |> text("cannot accept subscription request: #{error}")
    end
  end

  # ---

  defp check_connection_alive(pid) do
    case :rpc.pinfo(pid) do
      {:badrpc, :nodedown} ->
        # The node the process was running on is no longer alive.
        {:error, :process_dead}

      :undefined ->
        # The node is alive, but the process is down.
        {:error, :process_dead}

      _ ->
        :ok
    end
  end

  # ---

  # All claims, from all Authorization tokens. Returns a Result.
  defp get_all_claims(headers) do
    headers
    |> JWT.parse_http_header()
    |> Enum.reduce(%{}, fn
      {:ok, claims}, acc -> Map.merge(acc, claims)
      {:error, error}, _acc -> throw(error)
    end)
    |> Result.ok()
  catch
    %JWT.DecodeError{} = error ->
      Result.err("invalid authorization header: #{Exception.message(error)}")
  end

  # ---

  defp parse_subscriptions(subscriptions) when is_list(subscriptions) do
    subscriptions
    |> Enum.map(&Subscription.new!/1)
    |> Result.ok()
  rescue
    error in Subscription.ValidationError ->
      Result.err("could not parse given subscriptions: #{Exception.message(error)}")
  end
end
