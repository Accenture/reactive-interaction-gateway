defmodule RigInboundGateway.EventSubscriptionTest do
  @moduledoc """
  Clients need to be able to add and remove subscriptions to their connection.
  """
  # Cannot be async because the extractor configuration is modified:
  use ExUnit.Case, async: false

  alias Socket.Web, as: WebSocket

  alias CloudEvent
  alias RigAuth.Jwt.Utils, as: Jwt
  alias RigInboundGateway.ExtractorConfig

  def external_port,
    do: Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][:port]

  def hostname, do: "localhost"

  def setup do
    on_exit(&ExtractorConfig.restore/0)
  end

  defp greeting_for(name),
    do:
      %{
        "cloudEventsVersion" => "0.1",
        "source" => Atom.to_string(__MODULE__),
        "eventType" => "greeting"
      }
      |> CloudEvent.new!()
      |> CloudEvent.with_data(%{"name" => name})

  defp greeting_for_alice, do: greeting_for("alice")

  defp greeting_for_bob, do: greeting_for("bob")

  defp update_subscriptions(connection_id, subscriptions, jwt \\ nil) do
    url =
      "http://#{hostname()}:#{external_port()}/_rig/v1/connection/sse/#{connection_id}/subscriptions"

    body = Jason.encode!(%{"subscriptions" => subscriptions})

    headers =
      [{"content-type", "application/json"}] ++
        if is_nil(jwt), do: [], else: [{"authorization", jwt}]

    %HTTPoison.Response{status_code: 204} = HTTPoison.put!(url, body, headers)
    :ok
  end

  defp submit_event(cloud_event) do
    url = "http://#{hostname()}:#{external_port()}/_rig/v1/events"

    %HTTPoison.Response{status_code: 202} =
      HTTPoison.post!(url, Jason.encode!(cloud_event), [{"content-type", "application/json"}])

    :ok
  end

  defp connection_id(welcome_event)
  defp connection_id(%{"data" => %{"connection_token" => connection_id}}), do: connection_id

  defdelegate url_encode_subscriptions(list), to: Jason, as: :encode!

  defmodule Client do
    @moduledoc false
    @type client :: pid | reference | atom
    @callback connect(params :: list) :: {:ok, pid}
    @callback disconnect(client) :: :ok
    @callback refute_receive(client) :: :ok
    @callback read_event(client, event_type :: String.t()) :: map()
    @callback read_welcome_event(client) :: map()
    @callback read_subscriptions_set_event(client) :: map()
  end

  defmodule SseClient do
    @moduledoc false
    @behaviour Client
    alias RigInboundGateway.EventSubscriptionTest, as: Test

    @impl true
    def connect(params \\ []) do
      params =
        if Keyword.has_key?(params, :subscriptions) do
          encoded_subscriptions = params[:subscriptions] |> Test.url_encode_subscriptions()
          Keyword.replace!(params, :subscriptions, encoded_subscriptions)
        else
          params
        end

      url =
        "http://#{Test.hostname()}:#{Test.external_port()}/_rig/v1/connection/sse?#{
          URI.encode_query(params)
        }"

      %HTTPoison.AsyncResponse{id: client} =
        HTTPoison.get!(url, %{},
          stream_to: self(),
          recv_timeout: 20_000
        )

      assert_receive %HTTPoison.AsyncStatus{code: 200}
      assert_receive %HTTPoison.AsyncHeaders{}

      {:ok, client}
    end

    @impl true
    def disconnect(client) do
      {:ok, ^client} = :hackney.stop_async(client)
      :ok
    end

    @impl true
    def refute_receive(_client) do
      receive do
        %HTTPoison.AsyncChunk{} = async_chunk ->
          raise "Unexpectedly received: #{inspect(async_chunk)}"
      after
        100 -> :ok
      end
    end

    @impl true
    def read_event(_client, event_type) do
      cloud_event = read_sse_chunk() |> extract_cloud_event()
      %{"eventType" => ^event_type} = cloud_event
    end

    @impl true
    def read_welcome_event(client), do: read_event(client, "rig.connection.create")

    @impl true
    def read_subscriptions_set_event(client), do: read_event(client, "rig.subscriptions_set")

    defp read_sse_chunk do
      receive do
        %HTTPoison.AsyncChunk{chunk: chunk} -> chunk
      after
        1_000 ->
          raise "No chunk to read after 1s. #{inspect(:erlang.process_info(self(), :messages))}"
      end
    end

    defp extract_cloud_event(sse_chunk) do
      sse_chunk
      |> String.split("\n", trim: true)
      |> Enum.reduce_while(nil, fn
        "data: " <> data, _acc -> {:halt, Jason.decode!(data)}
        _x, _acc -> {:cont, nil}
      end)
      |> case do
        nil -> raise "Failed to extract CloudEvent from chunk: #{inspect(sse_chunk)}"
        cloud_event -> cloud_event
      end
    end
  end

  defmodule WsClient do
    @moduledoc false
    @behaviour Client
    alias RigInboundGateway.EventSubscriptionTest, as: Test

    @impl true
    def connect(params \\ []) do
      params =
        if Keyword.has_key?(params, :subscriptions) do
          encoded_subscriptions = params[:subscriptions] |> Test.url_encode_subscriptions()
          Keyword.replace!(params, :subscriptions, encoded_subscriptions)
        else
          params
        end

      WebSocket.connect(Test.hostname(), Test.external_port(), %{
        path: "/_rig/v1/connection/ws?#{URI.encode_query(params)}",
        protocol: ["ws"]
      })
    end

    @impl true
    def disconnect(client) do
      :ok = WebSocket.close(client)
    end

    @impl true
    def refute_receive(client) do
      case WebSocket.recv(client, timeout: 100) do
        {:ping, _} -> client.refute_receive(client)
        {:ok, packet} -> raise "Unexpectedly received: #{inspect(packet)}"
        {:error, _} -> :ok
      end
    end

    @impl true
    def read_event(client, event_type) do
      {:text, data} = WebSocket.recv!(client)
      cloud_event = Jason.decode!(data)
      %{"eventType" => ^event_type} = cloud_event
    end

    @impl true
    def read_welcome_event(client), do: read_event(client, "rig.connection.create")

    @impl true
    def read_subscriptions_set_event(client), do: read_event(client, "rig.subscriptions_set")
  end

  @clients [SseClient, WsClient]

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

      jwt = Jwt.generate(%{"username" => "alice"})
      expected_subscriptions = [%{"eventType" => "greeting", "oneOf" => [%{"name" => "alice"}]}]

      for client <- @clients do
        {:ok, ref} = client.connect(jwt: jwt)
        client.read_welcome_event(ref)

        assert %{"data" => ^expected_subscriptions} = client.read_subscriptions_set_event(ref)

        client.disconnect(ref)
      end
    end

    test "Connecting with both a subscriptions and a jwt parameter combines all subscriptions." do
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

      jwt = Jwt.generate(%{"username" => "alice"})
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

      jwt = Jwt.generate(%{"username" => "alice"})
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

      jwt = Jwt.generate(%{"username" => "alice"})
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

      jwt = Jwt.generate(%{"username" => "alice"})
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
