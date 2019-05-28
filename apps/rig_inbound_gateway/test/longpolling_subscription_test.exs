defmodule RigInboundGateway.EventSubscriptionTest do
  @moduledoc """
  Clients need to be able to add and remove subscriptions to their connection.
  """
  # Cannot be async because the extractor configuration is modified:
  use ExUnit.Case, async: false

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
  alias RigCloudEvents.CloudEvent
  alias RigInboundGateway.ExtractorConfig

  alias LongpollingClient

  @hostname "localhost"
  @eventhub_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][
                   :port
                 ]

  def setup do
    on_exit(&ExtractorConfig.restore/0)
  end

  defp greeting_for(name),
    do:
      CloudEvent.parse!(%{
        specversion: "0.2",
        type: "greeting",
        source: Atom.to_string(__MODULE__),
        id: UUID.uuid4(),
        data: %{name: name}
      })

  defp greeting_for_alice, do: greeting_for("alice")

  defp greeting_for_bob, do: greeting_for("bob")

  defp update_subscriptions(connection_id, subscriptions, jwt \\ nil) do
    url =
      "http://#{@hostname}:#{@eventhub_port}/_rig/v1/connection/longpolling/#{connection_id}/subscriptions"

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

  defp submit_event(%CloudEvent{json: json}) do
    url = "http://#{@hostname}:#{@eventhub_port}/_rig/v1/events"

    %HTTPoison.Response{status_code: 202} =
      HTTPoison.post!(url, json, [{"content-type", "application/json"}])

    :ok
  end

  defp connection_id(welcome_event)
  defp connection_id(%{"data" => %{"connection_token" => connection_id}}), do: connection_id

  describe "Connections and subscriptions:" do
    test "Connecting with no parameters causes empty subscription set." do
      {:ok, cookies} = LongpollingClient.connect()
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)

      subscriptions_set_event = Enum.at(events, 1)

      assert %{"data" => []} = subscriptions_set_event
    end

    test "Connecting with subscriptions parameter sets up the subscriptions." do
      subscriptions = [%{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}]

      {:ok, cookies} = LongpollingClient.connect(subscriptions: subscriptions)
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)

      subscriptions_set_event = Enum.at(events, 1)

      assert %{"data" => ^subscriptions} = subscriptions_set_event
    end

    test "Connecting with jwt parameter sets up automatic subscriptions." do
      ExtractorConfig.set(%{
        "greeting" => %{
          "name" => %{
            "stable_field_index" => 1,
            "event" => %{
              "json_pointer" => "/data/name"
            },
            "jwt" => %{
              "json_pointer" => "/username"
            }
          }
        }
      })

      jwt = JWT.encode(%{"username" => "alice"})
      expected_subscriptions = [%{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}]

      {:ok, cookies} = LongpollingClient.connect(jwt: jwt)
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)

      subscriptions_set_event = Enum.at(events, 1)

      assert %{"data" => ^expected_subscriptions} = subscriptions_set_event
    end

    test "Connecting with both a subscriptions and a JWT parameter combines all subscriptions." do
      ExtractorConfig.set(%{
        "greeting" => %{
          "name" => %{
            "stable_field_index" => 1,
            "event" => %{
              "json_pointer" => "/data/name"
            },
            "jwt" => %{
              "json_pointer" => "/username"
            }
          }
        }
      })

      jwt = JWT.encode(%{"username" => "alice"})
      automatic_subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
      manual_subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "bob"}]}

      {:ok, cookies} = LongpollingClient.connect(jwt: jwt, subscriptions: [manual_subscription])
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)

      subscriptions_set_event = Enum.at(events, 1)

      %{"data" => actual_subscriptions} = subscriptions_set_event

      assert actual_subscriptions in [
               [automatic_subscription, manual_subscription],
               [manual_subscription, automatic_subscription]
             ]
    end

    test "Replacing subscriptions without passing a JWT removes automatic subscriptions." do
      ExtractorConfig.set(%{
        "greeting" => %{
          "name" => %{
            "stable_field_index" => 1,
            "event" => %{
              "json_pointer" => "/data/name"
            },
            "jwt" => %{
              "json_pointer" => "/username"
            }
          }
        }
      })

      jwt = JWT.encode(%{"username" => "alice"})
      automatic_subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
      manual_subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "bob"}]}

      # Connect with JWT but don't pass any subscriptions:
      {:ok, cookies} = LongpollingClient.connect(jwt: jwt)
      {:ok, events, cookies} = LongpollingClient.read_events(cookies)

      # According to the extractor config, the JWT gives us an automatic subscription:
      subscriptions_set_event = Enum.at(events, 1)
      %{"data" => [^automatic_subscription]} = subscriptions_set_event

      # Use the connection ID to replace the subscriptions:
      welcome_event = Enum.at(events, 0)

      connection_id(welcome_event)
      |> update_subscriptions([manual_subscription])

      # Because we haven't passed the JWT, the automatic subscription is gone:
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)
      subscriptions_set_event = Enum.at(events, 0)
      %{"data" => [^manual_subscription]} = subscriptions_set_event
    end

    test "Replacing subscriptions with an empty set while passing a JWT sets up automatic subscriptions." do
      ExtractorConfig.set(%{
        "greeting" => %{
          "name" => %{
            "stable_field_index" => 1,
            "event" => %{
              "json_pointer" => "/data/name"
            },
            "jwt" => %{
              "json_pointer" => "/username"
            }
          }
        }
      })

      jwt = JWT.encode(%{"username" => "alice"})
      automatic_subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}

      # Connect without subscribing to anything:
      {:ok, cookies} = LongpollingClient.connect()
      {:ok, events, cookies} = LongpollingClient.read_events(cookies)

      # We shouldn't be subscribed to anything:
      subscriptions_set_event = Enum.at(events, 1)
      %{"data" => []} = subscriptions_set_event

      # Use the connection ID to obtain automatic subscriptions:
      welcome_event = Enum.at(events, 0)

      connection_id(welcome_event)
      |> update_subscriptions([], jwt)

      # We haven't passed any subscriptions, but we should've got the JWT based one automatically:
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)
      subscriptions_set_event = Enum.at(events, 0)
      %{"data" => [^automatic_subscription]} = subscriptions_set_event
    end

    test "Replacing subscriptions while passing a JWT combines passed with automatic subscriptions." do
      ExtractorConfig.set(%{
        "greeting" => %{
          "name" => %{
            "stable_field_index" => 1,
            "event" => %{
              "json_pointer" => "/data/name"
            },
            "jwt" => %{
              "json_pointer" => "/username"
            }
          }
        }
      })

      jwt = JWT.encode(%{"username" => "alice"})
      automatic_subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
      initial_subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "bob"}]}
      new_subscription = %{"eventType" => "greeting", "oneOf" => [%{"name" => "charlie"}]}

      {:ok, cookies} = LongpollingClient.connect(subscriptions: [initial_subscription])
      {:ok, events, cookies} = LongpollingClient.read_events(cookies)

      subscriptions_set_event = Enum.at(events, 1)
      %{"data" => [^initial_subscription]} = subscriptions_set_event

      welcome_event = Enum.at(events, 0)

      connection_id(welcome_event)
      |> update_subscriptions([new_subscription], jwt)

      # We should no longer see the initial subscription, but the new one and the JWT based one:
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)

      subscriptions_set_event = Enum.at(events, 0)
      %{"data" => actual_subscriptions} = subscriptions_set_event

      assert actual_subscriptions in [
               [automatic_subscription, new_subscription],
               [new_subscription, automatic_subscription]
             ]
    end

    test "An invalid subscription causes the request to fail." do
      invalid_subscription = %{"this" => "is not", "a" => "subscription"}

      {:ok, cookies} = LongpollingClient.connect(subscriptions: [])
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)

      subscriptions_set_event = Enum.at(events, 1)
      %{"data" => []} = subscriptions_set_event

      welcome_event = Enum.at(events, 0)

      error =
        assert_raise SubscriptionError, fn ->
          welcome_event
          |> connection_id()
          |> update_subscriptions([invalid_subscription])
        end

      assert error.code == 400
      assert error.body =~ ~r/could not parse given subscriptions/
    end

    test "An invalid JWT causes the request to fail." do
      invalid_jwt = "this is not a valid JWT"

      {:ok, cookies} = LongpollingClient.connect(subscriptions: [])
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)

      subscriptions_set_event = Enum.at(events, 1)
      %{"data" => []} = subscriptions_set_event

      welcome_event = Enum.at(events, 0)

      error =
        assert_raise SubscriptionError, fn ->
          welcome_event
          |> connection_id()
          |> update_subscriptions([], invalid_jwt)
        end

      assert error.code == 400
      assert error.body =~ ~r/invalid authorization header/
    end
  end

  describe "Receiving events:" do
    test "Adding and removing subscriptions is in effect immediately." do
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

      {:ok, cookies} = LongpollingClient.connect(subscriptions: [])
      {:ok, events, cookies} = LongpollingClient.read_events(cookies)

      welcome_event = Enum.at(events, 0)

      # By default, greetings to Alice are not forwarded:
      :ok = submit_event(greeting_for_alice())
      {:ok, events, cookies} = LongpollingClient.read_events(cookies)
      assert events == []

      # Subscribe to greetings for Alice:
      :ok =
        connection_id(welcome_event)
        |> update_subscriptions([
          %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
        ])

      {:ok, _events, cookies} = LongpollingClient.read_events(cookies)

      # Now a greeting to Alice is forwarded:
      :ok = submit_event(greeting_for_alice())
      {:ok, events, cookies} = LongpollingClient.read_events(cookies)
      assert %{"data" => %{"name" => "alice"}} = Enum.at(events, 0)

      # But a greeting to Bob is not:
      :ok = submit_event(greeting_for_bob())
      {:ok, events, cookies} = LongpollingClient.read_events(cookies)
      assert events == []

      # We remove the subscription again:
      :ok =
        connection_id(welcome_event)
        |> update_subscriptions([])

      {:ok, _events, cookies} = LongpollingClient.read_events(cookies)

      # After this, greetings to Alice are no longer forwarded:
      :ok = submit_event(greeting_for_alice())
      {:ok, events, _cookies} = LongpollingClient.read_events(cookies)
      assert events == []
    end
  end
end
