defmodule RigInboundGateway.EventSubmissionTest do
  @moduledoc """
  Assures that RIG doesn't change events.
  """

  # Cannot be async because the extractor configuration is modified:
  use ExUnit.Case, async: false

  alias HTTPoison
  alias Jason

  alias RigInboundGateway.ExtractorConfig

  alias SseClient
  alias WsClient

  @clients [SseClient, WsClient]

  @hostname "localhost"
  @eventhub_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][
                   :port
                 ]
  @base_url "http://#{@hostname}:#{@eventhub_port}/_rig"
  @submission_url "#{@base_url}/v1/events"

  def setup do
    on_exit(&ExtractorConfig.restore/0)
  end

  defp update_subscriptions(connection_id, subscriptions, jwt \\ nil) do
    url = "#{@base_url}/v1/connection/sse/#{connection_id}/subscriptions"

    body = Jason.encode!(%{"subscriptions" => subscriptions})

    headers =
      [{"accept", "application/json"}, {"content-type", "application/json"}] ++
        if is_nil(jwt), do: [], else: [{"authorization", "Bearer #{jwt}"}]

    %HTTPoison.Response{status_code: 204} = HTTPoison.put!(url, body, headers)
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
      event_0_1 = """
      {
        "additional top-level property": true,
        "cloudEventsVersion": "0.1",
        "eventID": "1",
        "eventType": "greeting",
        "source": "nil"
      }
      """

      event_0_2 = """
      {
        "additional top-level property": true,
        "id": "2",
        "source": "nil",
        "specversion": "0.2",
        "type": "greeting"
      }
      """

      for body <- [event_0_1, event_0_2] do
        headers = %{"content-type" => "application/json"}
        %{status_code: status_code} = HTTPoison.post!(@submission_url, body, headers)
        assert status_code == 202
        # The received event still has that additional property:
        assert %{"additional top-level property" => true} = client.read_event(ref, "greeting")
      end
    end
  end

  describe "CloudEvent HTTP binary mode (header=metadata, body=data):" do
    test """
    Given the ce-specversion header and the content type application/json, the body is \
    interpreted as the JSON encoded data field.\
    """ do
      ExtractorConfig.set(%{
        "greeting" => %{
          "name" => %{
            "stable_field_index" => 1,
            "event" => %{
              "json_pointer" => "/data/name"
            }
          }
        }
      })

      # We use a client to ensure the data is interpreted the right way:
      [client | _] = @clients
      {:ok, ref} = client.connect()
      welcome_event = client.read_welcome_event(ref)
      _ = client.read_subscriptions_set_event(ref)
      subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
      :ok = connection_id(welcome_event) |> update_subscriptions([subscription])
      _ = client.read_subscriptions_set_event(ref)

      # The body is the data field:
      body = ~S({"name": "alice"})
      event_source = Atom.to_string(__MODULE__)
      event_id = UUID.uuid4()

      headers = %{
        "content-type" => "application/json",
        "ce-specversion" => "0.2",
        "ce-type" => "greeting",
        "ce-source" => event_source,
        "ce-id" => event_id
      }

      %{status_code: status_code, body: body} = HTTPoison.post!(@submission_url, body, headers)
      assert status_code == 202, "#{status_code} #{inspect(body)}"
      # We receive the event in structured mode:
      assert %{
               "specversion" => "0.2",
               "type" => "greeting",
               "source" => ^event_source,
               "id" => ^event_id,
               "data" => %{
                 "name" => "alice"
               }
             } = client.read_event(ref, "greeting")
    end

    test "Events of media types unknown to RIG are still forwarded." do
      ExtractorConfig.set(%{})

      # We use a client to ensure the data is interpreted the right way:
      [client | _] = @clients
      {:ok, ref} = client.connect()
      welcome_event = client.read_welcome_event(ref)
      _ = client.read_subscriptions_set_event(ref)
      subscription = %{"eventType" => "greeting"}
      :ok = connection_id(welcome_event) |> update_subscriptions([subscription])
      _ = client.read_subscriptions_set_event(ref)

      # The body is the data field and we "encode" it as plain text:
      req_body = "The name this event carries is »Alice«."
      event_source = Atom.to_string(__MODULE__)
      event_id = UUID.uuid4()

      headers = %{
        "content-type" => "text/plain",
        "ce-specversion" => "0.2",
        "ce-type" => "greeting",
        "ce-source" => event_source,
        "ce-id" => event_id
      }

      %{status_code: status_code, body: resp_body} =
        HTTPoison.post!(@submission_url, req_body, headers)

      assert status_code == 202, "#{status_code} #{inspect(resp_body)}"
      # We receive the event in structured mode:
      assert %{
               "specversion" => "0.2",
               "type" => "greeting",
               "source" => ^event_source,
               "id" => ^event_id,
               "contenttype" => "text/plain",
               "data" => ^req_body
             } = client.read_event(ref, "greeting")
    end
  end

  describe "CloudEvent HTTP structured mode (body=metadata+data):" do
    test """
    Given the content type application/cloudevents+json, the body is interpreted as a \
    JSON encoded CloudEvent.\
    """ do
      ExtractorConfig.set(%{
        "greeting" => %{
          "name" => %{
            "stable_field_index" => 1,
            "event" => %{
              "json_pointer" => "/data/name"
            }
          }
        }
      })

      # We use a client to ensure the data is interpreted the right way:
      [client | _] = @clients
      {:ok, ref} = client.connect()
      welcome_event = client.read_welcome_event(ref)
      _ = client.read_subscriptions_set_event(ref)
      subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
      :ok = connection_id(welcome_event) |> update_subscriptions([subscription])
      _ = client.read_subscriptions_set_event(ref)

      event_source = Atom.to_string(__MODULE__)
      event_id = UUID.uuid4()

      body = """
      {
        "specversion": "0.2",
        "type": "greeting",
        "source": "#{event_source}",
        "id": "#{event_id}",
        "data": {"name": "alice"}
      }
      """

      # Here we use the type for JSON-encoded CloudEvents according to the spec:
      headers = %{
        "content-type" => "application/cloudevents+json"
      }

      %{status_code: status_code, body: body} = HTTPoison.post!(@submission_url, body, headers)
      assert status_code == 202, "#{status_code} #{inspect(body)}"
      # We receive the event in structured mode:
      assert %{
               "specversion" => "0.2",
               "type" => "greeting",
               "source" => ^event_source,
               "id" => ^event_id,
               "data" => %{
                 "name" => "alice"
               }
             } = client.read_event(ref, "greeting")
    end

    test """
    Given only standard headers and the content type application/json, the body is \
    interpreted as a JSON encoded CloudEvent.\
    """ do
      ExtractorConfig.set(%{
        "greeting" => %{
          "name" => %{
            "stable_field_index" => 1,
            "event" => %{
              "json_pointer" => "/data/name"
            }
          }
        }
      })

      # We use a client to ensure the data is interpreted the right way:
      [client | _] = @clients
      {:ok, ref} = client.connect()
      welcome_event = client.read_welcome_event(ref)
      _ = client.read_subscriptions_set_event(ref)
      subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
      :ok = connection_id(welcome_event) |> update_subscriptions([subscription])
      _ = client.read_subscriptions_set_event(ref)

      # For proper binary mode we'd set the ce-* headers now, but we provide a fallback
      # for the way we did this before the transport spec came around: we allow
      # structured mode with content-type application/json in addition
      # to the application/cloudevents+json content type.

      event_source = Atom.to_string(__MODULE__)
      event_id = UUID.uuid4()

      body = """
      {
        "specversion": "0.2",
        "type": "greeting",
        "source": "#{event_source}",
        "id": "#{event_id}",
        "data": {"name": "alice"}
      }
      """

      headers = %{
        "content-type" => "application/json"
      }

      %{status_code: status_code, body: body} = HTTPoison.post!(@submission_url, body, headers)
      assert status_code == 202, "#{status_code} #{inspect(body)}"
      # We receive the event in structured mode:
      assert %{
               "specversion" => "0.2",
               "type" => "greeting",
               "source" => ^event_source,
               "id" => ^event_id,
               "data" => %{
                 "name" => "alice"
               }
             } = client.read_event(ref, "greeting")
    end
  end
end
