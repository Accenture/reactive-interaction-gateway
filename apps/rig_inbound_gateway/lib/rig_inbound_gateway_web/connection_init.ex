defmodule RigInboundGatewayWeb.ConnectionInit do
  @moduledoc """
  Cowboy WebSocket handler.

  As soon as Phoenix pulls in Cowboy 2 this will have to be rewritten using the
  :cowboy_websocket behaviour.
  """

  require Logger

  alias Rig.Subscription
  alias RIG.Subscriptions
  alias RigAuth.AuthorizationCheck.Request
  alias RigAuth.AuthorizationCheck.Subscription, as: SubscriptionAuthZ

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
      "new #{conn_type} connection (pid=#{inspect(self())}, params=#{
        inspect(request.query_params)
      })"
    end)

    jwt =
      case request.auth_info do
        nil -> nil
        %{auth_tokens: [{"bearer", jwt}]} -> jwt
      end

    with {:ok, jwt_subs} <-
           Subscriptions.from_token(jwt),
         true = String.starts_with?(request.content_type, "application/json"),
         {:ok, query_subs} <-
           Subscriptions.from_json(request.body),
         subscriptions = Enum.uniq(jwt_subs ++ query_subs),
         :ok <- SubscriptionAuthZ.check_authorization(request) do
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
        on_error.("Subscription denied (not authorized).")
    end
  end
end
