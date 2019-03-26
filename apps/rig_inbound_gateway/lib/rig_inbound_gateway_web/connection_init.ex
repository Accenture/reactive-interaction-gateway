defmodule RigInboundGatewayWeb.ConnectionInit do
  @moduledoc """
  Cowboy WebSocket handler.

  As soon as Phoenix pulls in Cowboy 2 this will have to be rewritten using the
  :cowboy_websocket behaviour.
  """

  require Logger

  alias Rig.Subscription
  alias RIG.Subscriptions

  # ---

  @type handler_response :: any
  @type on_success :: ([Subscription.t()] -> handler_response)
  @type on_error :: (reason :: String.t() -> handler_response)
  @spec set_up(String.t(), map, on_success, on_error, pos_integer(), pos_integer()) ::
          handler_response
  def set_up(
        conn_type,
        query_params,
        on_success,
        on_error,
        heartbeat_interval_ms,
        subscription_refresh_interval_ms
      ) do
    Logger.debug(fn ->
      "new #{conn_type} connection (pid=#{inspect(self())}, params=#{inspect(query_params)})"
    end)

    with {:ok, jwt_subs} <- Subscriptions.from_token(query_params["jwt"]),
         {:ok, query_subs} <-
           Map.get(query_params, "subscriptions") |> Subscriptions.from_json() do
      subscriptions = Enum.uniq(jwt_subs ++ query_subs)

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
    end
  end
end
