defmodule RigInboundGateway.EventSubmissionTest do
  @moduledoc """
  Assures that RIG doesn't change events.
  """

  # Cannot be async because the extractor configuration is modified:
  use ExUnit.Case, async: false

  alias HTTPoison
  alias Jason

  alias CloudEvent
  alias RigInboundGateway.ExtractorConfig

  alias SSeClient
  alias WsClient

  @clients [SseClient, WsClient]

  @hostname "localhost"
  @eventhub_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][
                   :port
                 ]

  def setup do
    on_exit(&ExtractorConfig.restore/0)
  end

  defp update_subscriptions(connection_id, subscriptions, jwt \\ nil) do
    url =
      "http://#{@hostname}:#{@eventhub_port}/_rig/v1/connection/sse/#{connection_id}/subscriptions"

    body = Jason.encode!(%{"subscriptions" => subscriptions})

    headers =
      [{"content-type", "application/json"}] ++
        if is_nil(jwt), do: [], else: [{"authorization", jwt}]

    %HTTPoison.Response{status_code: 204} = HTTPoison.put!(url, body, headers)
    :ok
  end

  defp submit_event(cloud_event) do
    url = "http://#{@hostname}:#{@eventhub_port}/_rig/v1/events"

    %HTTPoison.Response{status_code: 202} =
      HTTPoison.post!(url, Jason.encode!(cloud_event), [{"content-type", "application/json"}])

    :ok
  end

  defp connection_id(welcome_event)
  defp connection_id(%{"data" => %{"connection_token" => connection_id}}), do: connection_id

  test "An event's top-level properties are retained also when not related to the CloudEvents spec." do
    ExtractorConfig.set(%{})

    for client <- @clients do
      {:ok, ref} = client.connect()
      welcome_event = client.read_welcome_event(ref)
      _ = client.read_subscriptions_set_event(ref)

      # Subscribe to greeting events:
      :ok = connection_id(welcome_event) |> update_subscriptions([%{"eventType" => "greeting"}])
      _ = client.read_subscriptions_set_event(ref)

      # A CloudEvents with extra top-level attributes not mentioned in the spec:
      event =
        CloudEvent.new!(%{
          "additional top-level property" => true,
          "cloudEventsVersion" => "0.1",
          "source" => Atom.to_string(__MODULE__),
          "eventType" => "greeting"
        })

      :ok = submit_event(event)

      # The received event still has that additional property:
      assert %{"additional top-level property" => true} = client.read_event(ref, "greeting")
    end
  end
end
