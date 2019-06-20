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
      for client <- @clients do
        {:ok, ref} = client.connect()
        client.read_welcome_event(ref)

        assert %{"data" => []} = client.read_subscriptions_set_event(ref)

        client.disconnect(ref)
      end
    end

    test "Connecting with subscriptions parameter sets up the subscriptions." do
      subscriptions = [%{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}]

      for client <- @clients do
        {:ok, ref} = client.connect(subscriptions: subscriptions)
        client.read_welcome_event(ref)

        assert %{"data" => ^subscriptions} = client.read_subscriptions_set_event(ref)

        client.disconnect(ref)
      end
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

      for client <- @clients do
        {:ok, ref} = client.connect(jwt: jwt)
        client.read_welcome_event(ref)

        assert %{"data" => ^expected_subscriptions} = client.read_subscriptions_set_event(ref)

        client.disconnect(ref)
      end
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

      for client <- @clients do
        {:ok, ref} = client.connect(jwt: jwt, subscriptions: [manual_subscription])
        client.read_welcome_event(ref)

        %{"data" => actual_subscriptions} = client.read_subscriptions_set_event(ref)

        assert actual_subscriptions in [
                 [automatic_subscription, manual_subscription],
                 [manual_subscription, automatic_subscription]
               ]

        client.disconnect(ref)
      end
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

      for client <- @clients do
        # Connect with JWT but don't pass any subscriptions:
        {:ok, ref} = client.connect(jwt: jwt)
        welcome_event = client.read_welcome_event(ref)

        # According to the extractor config, the JWT gives us an automatic subscription:
        %{"data" => [^automatic_subscription]} = client.read_subscriptions_set_event(ref)

        # Use the connection ID to replace the subscriptions:
        connection_id(welcome_event)
        |> update_subscriptions([manual_subscription])

        # Because we haven't passed the JWT, the automatic subscription is gone:
        %{"data" => [^manual_subscription]} = client.read_subscriptions_set_event(ref)

        client.disconnect(ref)
      end
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

      for client <- @clients do
        # Connect without subscribing to anything:
        {:ok, ref} = client.connect()
        welcome_event = client.read_welcome_event(ref)

        # We shouldn't be subscribed to anything:
        %{"data" => []} = client.read_subscriptions_set_event(ref)

        # Use the connection ID to obtain automatic subscriptions:
        connection_id(welcome_event)
        |> update_subscriptions([], jwt)

        # We haven't passed any subscriptions, but we should've got the JWT based one automatically:
        %{"data" => [^automatic_subscription]} = client.read_subscriptions_set_event(ref)

        client.disconnect(ref)
      end
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

      for client <- @clients do
        {:ok, ref} = client.connect(subscriptions: [initial_subscription])
        welcome_event = client.read_welcome_event(ref)

        %{"data" => [^initial_subscription]} = client.read_subscriptions_set_event(ref)

        connection_id(welcome_event)
        |> update_subscriptions([new_subscription], jwt)

        # We should no longer see the initial subscription, but the new one and the JWT based one:
        %{"data" => actual_subscriptions} = client.read_subscriptions_set_event(ref)

        assert actual_subscriptions in [
                 [automatic_subscription, new_subscription],
                 [new_subscription, automatic_subscription]
               ]

        client.disconnect(ref)
      end
    end

    test "An invalid subscription causes the request to fail." do
      invalid_subscription = %{"this" => "is not", "a" => "subscription"}

      for client <- @clients do
        {:ok, ref} = client.connect(subscriptions: [])
        welcome_event = client.read_welcome_event(ref)

        %{"data" => []} = client.read_subscriptions_set_event(ref)

        error =
          assert_raise SubscriptionError, fn ->
            welcome_event
            |> connection_id()
            |> update_subscriptions([invalid_subscription])
          end

        assert error.code == 400
        assert error.body =~ ~r/could not parse given subscriptions/

        # The request has failed, so there should be no subscriptions_set event:
        :ok = client.refute_receive(ref)

        client.disconnect(ref)
      end
    end

    test "An invalid JWT causes the request to fail." do
      invalid_jwt = "this is not a valid JWT"

      for client <- @clients do
        {:ok, ref} = client.connect(subscriptions: [])
        welcome_event = client.read_welcome_event(ref)

        %{"data" => []} = client.read_subscriptions_set_event(ref)

        error =
          assert_raise SubscriptionError, fn ->
            welcome_event
            |> connection_id()
            |> update_subscriptions([], invalid_jwt)
          end

        assert error.body =~ ~r/invalid authorization header/
        assert error.code == 400

        # The request has failed, so there should be no subscriptions_set event:
        :ok = client.refute_receive(ref)

        client.disconnect(ref)
      end
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

      for client <- @clients do
        {:ok, ref} = client.connect()
        welcome_event = client.read_welcome_event(ref)
        _ = client.read_subscriptions_set_event(ref)

        # By default, greetings to Alice are not forwarded:
        :ok = submit_event(greeting_for_alice())
        assert :ok = client.refute_receive(ref)

        # Subscribe to greetings for Alice:
        :ok =
          connection_id(welcome_event)
          |> update_subscriptions([
            %{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}
          ])

        _ = client.read_subscriptions_set_event(ref)

        # Now a greeting to Alice is forwarded:
        :ok = submit_event(greeting_for_alice())
        assert %{"data" => %{"name" => "alice"}} = client.read_event(ref, "greeting")

        # But a greeting to Bob is not:
        :ok = submit_event(greeting_for_bob())
        assert :ok = client.refute_receive(ref)

        # We remove the subscription again:
        :ok =
          connection_id(welcome_event)
          |> update_subscriptions([])

        _ = client.read_subscriptions_set_event(ref)

        # After this, greetings to Alice are no longer forwarded:
        :ok = submit_event(greeting_for_alice())
        assert :ok = client.refute_receive(ref)
      end
    end
  end
end
