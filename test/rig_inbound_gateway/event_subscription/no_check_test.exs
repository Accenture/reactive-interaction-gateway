defmodule RigInboundGateway.EventSubscription.NoCheckTest do
  @moduledoc """
  The no_check setting lets anyone subscribe to anything.
  """
  # Cannot be async because environment variables are modified:
  use ExUnit.Case, async: false

  defmodule SubscriptionError do
    defexception [:code, :body]
    def exception(code, body), do: %__MODULE__{code: code, body: body}

    def message(%__MODULE__{code: code, body: body}),
      do: "updating subscriptions failed with #{inspect(code)}: #{inspect(body)}"
  end

  alias HTTPoison
  alias Jason

  @clients [SseClient, WsClient]

  @hostname "localhost"
  @eventhub_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  @var_name "SUBSCRIPTION_CHECK"
  @orig_val System.get_env(@var_name)
  setup_all do
    System.put_env(@var_name, "no_check")

    on_exit(fn ->
      case @orig_val do
        nil -> System.delete_env(@var_name)
        _ -> System.put_env(@var_name, @orig_val)
      end
    end)
  end

  defp connection_id(welcome_event)
  defp connection_id(%{"data" => %{"connection_token" => connection_id}}), do: connection_id

  defp update_subscriptions(connection_id, subscriptions, jwt \\ nil) do
    url =
      "http://#{@hostname}:#{@eventhub_port}/_rig/v1/connection/sse/#{connection_id}/subscriptions"

    body = Jason.encode!(%{"subscriptions" => subscriptions})

    headers =
      [{"content-type", "application/json"}] ++
        if is_nil(jwt), do: [], else: [{"authorization", "Bearer #{jwt}"}]

    case HTTPoison.put!(url, body, headers) do
      %HTTPoison.Response{status_code: 204} ->
        :ok

      %HTTPoison.Response{status_code: code, body: body} ->
        raise SubscriptionError, code: code, body: body
    end
  end

  test "Anyone can subscribe to anything." do
    for client <- @clients do
      # Is accepted when passed immediately:
      {:ok, ref} = client.connect(subscriptions: [%{"eventType" => "greeting1"}])
      {welcome_event, ref} = client.read_welcome_event(ref)

      assert {%{"data" => [%{"eventType" => "greeting1", "oneOf" => []}]}, ref} =
               client.read_subscriptions_set_event(ref)

      # Is also accepted when using the subscriptions endpoint:
      assert :ok =
               welcome_event
               |> connection_id()
               |> update_subscriptions([%{"eventType" => "greeting2"}])

      assert {%{"data" => [%{"eventType" => "greeting2", "oneOf" => []}]}, ref} =
               client.read_subscriptions_set_event(ref)

      client.disconnect(ref)
    end
  end
end
