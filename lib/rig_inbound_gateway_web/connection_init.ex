defmodule RigInboundGatewayWeb.ConnectionInit do
  @moduledoc """
  Cowboy WebSocket handler.

  As soon as Phoenix pulls in Cowboy 2 this will have to be rewritten using the
  :cowboy_websocket behaviour.
  """

  require Logger

  alias RIG.AuthorizationCheck.Request
  alias RIG.AuthorizationCheck.Subscription, as: SubscriptionAuthZ
  alias RIG.JWT
  alias RIG.Session
  alias Rig.Subscription
  alias RIG.Subscriptions

  # ---

  @type handler_response :: any
  @type on_success :: ([Subscription.t()] -> handler_response)
  @type on_error :: (reason :: String.t() -> handler_response)
  @spec set_up(String.t(), Request.t(), on_success, on_error, pos_integer(), pos_integer()) ::
          handler_response
  def set_up(
        conn_type,
        request,
        on_success,
        on_error,
        heartbeat_interval_ms,
        subscription_refresh_interval_ms
      ) do
    Logger.debug(fn ->
      "new #{conn_type} connection (pid=#{inspect(self())}, params=#{inspect(request)})"
    end)

    jwt =
      case request.auth_info do
        nil -> nil
        %{auth_tokens: [{"bearer", jwt}]} -> jwt
      end

    # TODO: EVENT: SETUP

    with {:ok, jwt_subs} <-
           Subscriptions.from_token(jwt),
         true = String.starts_with?(request.content_type, "application/json"),
         {:ok, query_subs} <-
           Subscriptions.from_json(request.body),
         subscriptions = Enum.uniq(jwt_subs ++ query_subs),
         :ok <- SubscriptionAuthZ.check_authorization(request) do
      # If the JWT is valid and points to a session, we associate this connection with
      # it. If that doesn't work out, we log a warning but don't tell the frontend -
      # it's not the frontend's fault anyway.
      check_and_register_session(jwt)
      |> Result.or_else(fn error ->
        Logger.warn(fn ->
          "Failed to associate the #{conn_type} connection #{inspect(self())} to its session: #{
            inspect(error)
          }"
        end)
      end)

      # We're going to accept the connection, so let's set up the heartbeat too:
      Process.send_after(self(), :heartbeat, heartbeat_interval_ms)

      # We register subscriptions:
      send(self(), {:set_subscriptions, subscriptions})
      # ..and schedule periodic refresh:
      Process.send_after(self(), :refresh_subscriptions, subscription_refresh_interval_ms)

      on_success.(subscriptions)
    else
      {:error, %Subscriptions.Error{} = e} ->
        on_error.(Exception.message(e))

      {:error, :not_authorized} ->
        Logger.debug(fn ->
          "Not authorized #{conn_type} with pid=#{inspect(self())}"
        end)

        on_error.("Subscription denied (not authorized).")
    end
  end

  # ---

  @spec check_and_register_session(map()) ::
          Result.t(
            any,
            {:failed_to_associate_to_session, %RIG.JWT.DecodeError{} | String.t()}
          )
  defp check_and_register_session(jwt)

  defp check_and_register_session(nil), do: {:ok, nil}

  defp check_and_register_session(jwt) do
    jwt
    |> JWT.parse_token()
    |> Result.and_then(fn claims -> Session.from_claims(claims) end)
    |> Result.map(fn session_name -> Session.register_connection(session_name, self()) end)
    |> Result.map_err(fn err -> {:failed_to_associate_to_session, err} end)
  end

  # ---

  @spec subscriptions_query_param_to_body(map) :: {:ok, String.t()} | {:error, String.t()}
  def subscriptions_query_param_to_body(query_params)

  def subscriptions_query_param_to_body(%{"subscriptions" => json_list})
      when byte_size(json_list) > 0 do
    case Jason.decode(json_list) do
      {:ok, list} ->
        Jason.encode(%{"subscriptions" => list})
        |> Result.map_err(fn ex ->
          msg = "Failed to encode subscriptions body from query parameters"
          Logger.warn("#{msg}: #{Exception.message(ex)}")
          "#{msg} (please see server logs for details)."
        end)

      {:error, %Jason.DecodeError{} = ex} ->
        {:error, "Failed to decode subscription list: #{Exception.message(ex)}"}
    end
  end

  def subscriptions_query_param_to_body(_), do: {:ok, nil}
end
