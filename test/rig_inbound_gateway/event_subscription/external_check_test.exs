defmodule RigInboundGateway.EventSubscription.ExternalCheckTest do
  @moduledoc """
  An external service may be used to allow or deny subscriptions.
  """
  # Cannot be async because environment variables are modified:
  use ExUnit.Case, async: false

  import FakeServer
  alias FakeServer.Response

  defmodule SubscriptionError do
    defexception [:code, :body]
    def exception(code, body), do: %__MODULE__{code: code, body: body}

    def message(%__MODULE__{code: code, body: body}),
      do: "updating subscriptions failed with #{inspect(code)}: #{inspect(body)}"
  end

  alias HTTPoison
  alias Jason
  alias UUID

  alias RIG.JWT

  @clients [SseClient, WsClient]

  @hostname "localhost"
  @eventhub_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]
  @fake_validation_service_port 59_348

  @var_name "SUBSCRIPTION_CHECK"
  @orig_val System.get_env(@var_name)
  setup_all do
    System.put_env(@var_name, "http://localhost:#{@fake_validation_service_port}")

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

  test_with_server "The external service can accept a subscription.",
    port: @fake_validation_service_port do
    # The fake subscription-validation service accepts anything:
    route("/", Response.ok!("Ok"))

    for client <- @clients do
      # Is accepted when passed immediately:
      {:ok, ref} = client.connect(subscriptions: [%{"eventType" => "greeting1"}])
      {welcome_event, ref} = client.read_welcome_event(ref)
      {_, ref} = client.read_subscriptions_set_event(ref)

      # Is also accepted when using the subscriptions endpoint:
      assert :ok =
               welcome_event
               |> connection_id()
               |> update_subscriptions([%{"eventType" => "greeting2"}])

      {_, ref} = client.read_subscriptions_set_event(ref)

      client.disconnect(ref)
    end
  end

  test_with_server "The external service can deny a subscription.",
    port: @fake_validation_service_port do
    # The fake subscription-validation service denies anything:
    route("/", Response.bad_request!("NO WAY!"))

    for client <- @clients do
      # Is denied when passed immediately:
      assert_raise TestClient.ConnectionError, fn ->
        client.connect(subscriptions: [%{"eventType" => "greeting1"}])
      end

      # Is also denied when using the subscriptions endpoint:
      {:ok, ref} = client.connect()
      {welcome_event, ref} = client.read_welcome_event(ref)

      assert_raise SubscriptionError, fn ->
        welcome_event
        |> connection_id()
        |> update_subscriptions([%{"eventType" => "greeting2"}])
      end

      client.disconnect(ref)
    end
  end

  test_with_server "The external service receives the Authorization header, even if the JWT it contains can't be validated.",
    port: @fake_validation_service_port do
    # The fake subscription-validation service accepts anything:
    route("/", fn
      %{headers: %{"authorization" => "Bearer " <> jwt}} when byte_size(jwt) > 0 ->
        Response.ok!("Ok")

      %{headers: headers} ->
        Response.bad_request!(
          "Expected a bearer token in the Authorization header, got: #{inspect(headers)}"
        )
    end)

    jwt = "use case: valid JWT but RIG doesn't have the validation key"

    for client <- @clients do
      {:ok, ref} = client.connect()
      {welcome_event, ref} = client.read_welcome_event(ref)

      assert :ok =
               welcome_event
               |> connection_id()
               |> update_subscriptions([%{"eventType" => "greeting"}], jwt)

      {_, ref} = client.read_subscriptions_set_event(ref)

      client.disconnect(ref)
    end
  end

  test_with_server "The external service receives the subscriptions in the request body.",
    port: @fake_validation_service_port do
    # The fake subscription-validation service:
    route("/", fn %{body: body} ->
      %{"subscriptions" => [%{"eventType" => "greeting"}]} = body
      Response.ok!()
    end)

    for client <- @clients do
      # Is accepted when passed immediately:
      {:ok, ref} = client.connect(subscriptions: [%{"eventType" => "greeting"}])
      {welcome_event, ref} = client.read_welcome_event(ref)
      {_, ref} = client.read_subscriptions_set_event(ref)

      # Is also accepted when using the subscriptions endpoint:
      assert :ok =
               welcome_event
               |> connection_id()
               |> update_subscriptions([%{"eventType" => "greeting"}])

      {_, ref} = client.read_subscriptions_set_event(ref)

      client.disconnect(ref)
    end
  end
end
