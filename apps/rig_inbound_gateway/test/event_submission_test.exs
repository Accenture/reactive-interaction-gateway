defmodule RigInboundGateway.EventSubmissionTest do
  @moduledoc """
  Assures that RIG doesn't change events.
  """

  # Cannot be async because the extractor configuration is modified:
  use ExUnit.Case, async: false

  alias HTTPoison
  alias Jason

  alias RigCloudEvents.CloudEvent
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

  defp submit_event(%CloudEvent{json: json}) do
    url = "http://#{@hostname}:#{@eventhub_port}/_rig/v1/events"

    %HTTPoison.Response{status_code: 202} =
      HTTPoison.post!(url, json, [{"content-type", "application/json"}])

    :ok
  end

  defp connection_id(welcome_event)
  defp connection_id(%{"data" => %{"connection_token" => connection_id}}), do: connection_id

  test "An event's top-level properties are retained also when not related to any CloudEvents spec." do
    ExtractorConfig.set(%{})

    for client <- @clients do
      {:ok, ref} = client.connect()
      welcome_event = client.read_welcome_event(ref)
      _ = client.read_subscriptions_set_event(ref)

      # Subscribe to greeting events:
      :ok = connection_id(welcome_event) |> update_subscriptions([%{"eventType" => "greeting"}])
      _ = client.read_subscriptions_set_event(ref)

      # CloudEvents with extra top-level attributes not mentioned in any spec:
      event_0_1 =
        CloudEvent.parse!(%{
          "additional top-level property" => true,
          "cloudEventsVersion" => "0.1",
          "eventType" => "greeting",
          "source" => Atom.to_string(__MODULE__),
          "eventID" => "1"
        })

      event_0_2 =
        CloudEvent.parse!(%{
          "additional top-level property" => true,
          "specversion" => "0.2",
          "type" => "greeting",
          "source" => Atom.to_string(__MODULE__),
          "id" => "2"
        })

      for event <- [event_0_1, event_0_2] do
        :ok = submit_event(event)
        # The received event still has that additional property:
        assert %{"additional top-level property" => true} = client.read_event(ref, "greeting")
      end
    end
  end
end
