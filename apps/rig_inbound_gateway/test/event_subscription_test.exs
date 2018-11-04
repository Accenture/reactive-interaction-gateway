defmodule RigInboundGateway.EventSubscriptionTest do
  @moduledoc """
  Clients need to be able to add and remove subscriptions to their connection.
  """
  # Cannot be async because the extractor configuration is modified
  use ExUnit.Case, async: false

  alias Rig.CloudEvent
  alias Rig.EventFilter.Sup, as: EventFilterSup

  @external_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][
                   :port
                 ]
  @external_url "http://localhost:#{@external_port}"

  def setup do
    extractor_config = System.get_env("EXTRACTORS")

    on_exit(fn ->
      # Restore extractor configuration:
      System.put_env("EXTRACTORS", extractor_config)
    end)
  end

  defp set_extractor_config(extractor_config) when is_map(extractor_config) do
    System.put_env("EXTRACTORS", Jason.encode!(extractor_config))

    for sup <- EventFilterSup.processes() do
      send(sup, :reload_config)
    end
  end

  defp greeting_without_name,
    do:
      %{
        "cloudEventsVersion" => "0.1",
        "source" => Atom.to_string(__MODULE__),
        "eventType" => "greeting"
      }
      |> CloudEvent.new!()
      |> Jason.encode!()

  defp greeting_for(name),
    do:
      %{
        "cloudEventsVersion" => "0.1",
        "source" => Atom.to_string(__MODULE__),
        "eventType" => "greeting"
      }
      |> CloudEvent.new!()
      |> CloudEvent.with_data(%{"name" => name})
      |> Jason.encode!()

  defp greeting_for_alice, do: greeting_for("alice")

  defp greeting_for_bob, do: greeting_for("bob")

  defp new_sse_connection do
    HTTPoison.get!("#{@external_url}/_rig/v1/connection/sse", %{},
      stream_to: self(),
      recv_timeout: 20_000
    )

    # Extract the connection token from the response:

    %{"data" => %{"connection_token" => connection_id}} =
      receive do
        %HTTPoison.AsyncChunk{chunk: chunk} ->
          chunk
          |> String.split("\n", trim: true)
          |> Enum.reduce_while(nil, fn
            "data: " <> data, _acc -> {:halt, Jason.decode!(data)}
            _x, _acc -> {:cont, nil}
          end)
      after
        1_000 -> nil
      end

    assert_received %HTTPoison.AsyncStatus{code: 200}
    assert_received %HTTPoison.AsyncHeaders{}

    connection_id
  end

  test "Adding and removing subscriptions is in effect immediately." do
    # Set up the extractor configuration:

    set_extractor_config(%{
      "greeting" => %{
        "name" => %{
          "stable_field_index" => 1,
          "event" => %{
            "json_pointer" => "/data/name"
          }
        }
      }
    })

    # Establish an SSE connection:

    connection_id = new_sse_connection()
    subscriptions_url = "#{@external_url}/_rig/v1/connection/sse/#{connection_id}/subscriptions"

    # By default, greetings to Alice are not forwarded:

    HTTPoison.post!(
      "#{@external_url}/_rig/v1/events",
      greeting_for_alice(),
      [{"content-type", "application/json"}]
    )

    refute_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}

    # Subscribe to greetings for Alice:

    HTTPoison.put!(
      subscriptions_url,
      Jason.encode!(%{
        "subscriptions" => [
          %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
        ]
      }),
      [{"content-type", "application/json"}]
    )

    assert_receive %HTTPoison.AsyncChunk{chunk: "event: rig.subscriptions_set\n" <> _}

    # Now a greeting to Alice is forwarded:

    HTTPoison.post!(
      "#{@external_url}/_rig/v1/events",
      greeting_for_alice(),
      [{"content-type", "application/json"}]
    )

    assert_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}

    # But a greeting to Bob is not:

    HTTPoison.post!(
      "#{@external_url}/_rig/v1/events",
      greeting_for_bob(),
      [{"content-type", "application/json"}]
    )

    refute_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}

    # We remove the subscription again:

    HTTPoison.put!(
      subscriptions_url,
      Jason.encode!(%{
        "subscriptions" => []
      }),
      [{"content-type", "application/json"}]
    )

    assert_receive %HTTPoison.AsyncChunk{chunk: "event: rig.subscriptions_set\n" <> _}

    # After this, greetings to Alice are no longer forwarded:

    HTTPoison.post!(
      "#{@external_url}/_rig/v1/events",
      greeting_for_alice(),
      [{"content-type", "application/json"}]
    )

    refute_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}
  end

  test "An event that lacks a value for a known field is only forwarded if there is no constraint related to that field." do
    set_extractor_config(%{
      "greeting" => %{
        "name" => %{
          "stable_field_index" => 1,
          "event" => %{
            "json_pointer" => "/data/name"
          }
        }
      }
    })

    connection_id = new_sse_connection()
    subscriptions_url = "#{@external_url}/_rig/v1/connection/sse/#{connection_id}/subscriptions"

    # Subscribe to all greetings:

    HTTPoison.put!(
      subscriptions_url,
      Jason.encode!(%{
        "subscriptions" => [
          %{"eventType" => "greeting"}
        ]
      }),
      [{"content-type", "application/json"}]
    )

    assert_receive %HTTPoison.AsyncChunk{chunk: "event: rig.subscriptions_set\n" <> _}

    # A greeting without a name value is forwarded:

    HTTPoison.post!(
      "#{@external_url}/_rig/v1/events",
      greeting_without_name(),
      [{"content-type", "application/json"}]
    )

    assert_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}

    # If we subscribe to greetings for Alice..

    HTTPoison.put!(
      subscriptions_url,
      Jason.encode!(%{
        "subscriptions" => [
          %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
        ]
      }),
      [{"content-type", "application/json"}]
    )

    assert_receive %HTTPoison.AsyncChunk{chunk: "event: rig.subscriptions_set\n" <> _}

    # ..the greeting without name is no longer forwarded:

    HTTPoison.post!(
      "#{@external_url}/_rig/v1/events",
      greeting_without_name(),
      [{"content-type", "application/json"}]
    )

    refute_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}
  end
end
