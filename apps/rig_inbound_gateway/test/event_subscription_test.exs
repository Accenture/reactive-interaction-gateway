defmodule RigInboundGateway.EventSubscriptionTest do
  @moduledoc """
  Clients need to be able to add and remove subscriptions to their connection.
  """
  # Cannot be async because the extractor configuration is modified
  use ExUnit.Case, async: false

  import Joken

  alias Rig.CloudEvent
  alias Rig.EventFilter.Sup, as: EventFilterSup

  @external_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][
                   :port
                 ]
  @external_url "http://localhost:#{@external_port}"
  @jwt_secret_key "mysecret"

  def setup do
    extractor_config = System.get_env("EXTRACTORS")

    on_exit(fn ->
      # Restore extractor configuration:
      System.put_env("EXTRACTORS", extractor_config)
    end)
  end

  defp generate_jwt(username) do
    token()
    |> with_exp
    |> with_signer(@jwt_secret_key |> hs256)
    |> with_claim("username", username)
    |> sign
    |> get_compact
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

  defp new_sse_connection(token \\ nil) do
    connection_url =
      if token,
        do: "#{@external_url}/_rig/v1/connection/sse?token=#{token}",
        else: "#{@external_url}/_rig/v1/connection/sse"

    HTTPoison.get!(connection_url, %{},
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

  defp new_ws_connection(token \\ nil) do
    path =
      if token,
        do: "/_rig/v1/connection/ws?token=#{token}",
        else: "/_rig/v1/connection/ws"

    {:ok, client} =
      Socket.Web.connect("localhost", @external_port, %{
        path: path,
        protocol: ["ws"]
      })

    # Extract the connection token from the response:

    {:text, data} = client |> Socket.Web.recv!()
    %{"data" => %{"connection_token" => connection_id}} = Jason.decode!(data)

    {connection_id, client}
  end

  describe "Server-sent events," do
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

    test "In case JWT is present in create subscription request it should automatically infer subscriptions from JWT." do
      # Set up the extractor configuration:

      set_extractor_config(%{
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

      # Establish an SSE connection:

      connection_id = new_sse_connection()
      subscriptions_url = "#{@external_url}/_rig/v1/connection/sse/#{connection_id}/subscriptions"
      token = generate_jwt("john.doe")

      HTTPoison.put!(
        subscriptions_url,
        Jason.encode!(%{
          "subscriptions" => []
        }),
        [
          {"content-type", "application/json"},
          {"authorization", token}
        ]
      )

      assert_receive %HTTPoison.AsyncChunk{chunk: "event: rig.subscriptions_set\n" <> _}

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for("john.doe"),
        [{"content-type", "application/json"}]
      )

      assert_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for("bob.doe"),
        [{"content-type", "application/json"}]
      )

      refute_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}
    end

    test "In case JWT is present in initial connection request it should automatically infer subscriptions from JWT." do
      # Set up the extractor configuration:

      set_extractor_config(%{
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

      # Establish an SSE connection:
      token = generate_jwt("john.doe")

      new_sse_connection(token)

      assert_receive %HTTPoison.AsyncChunk{chunk: "event: rig.subscriptions_set\n" <> _}

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for("john.doe"),
        [{"content-type", "application/json"}]
      )

      assert_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for("bob.doe"),
        [{"content-type", "application/json"}]
      )

      refute_receive %HTTPoison.AsyncChunk{chunk: "event: greeting\n" <> _}
    end
  end

  describe "Websocket," do
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

      # Establish a WS connection:

      {connection_id, socket_client} = new_ws_connection()
      subscriptions_url = "#{@external_url}/_rig/v1/connection/ws/#{connection_id}/subscriptions"

      # By default, greetings to Alice are not forwarded:

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for_alice(),
        [{"content-type", "application/json"}]
      )

      assert_raise Socket.Error, "timeout", fn ->
        socket_client |> Socket.Web.recv!(%{timeout: 100})
      end

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

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type, "data" => data} = Jason.decode!(response)

      assert event_type == "rig.subscriptions_set"
      assert data == [%{"constraints" => [%{"name" => "alice"}], "event_type" => "greeting"}]

      # Now a greeting to Alice is forwarded:

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for_alice(),
        [{"content-type", "application/json"}]
      )

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type, "data" => data} = Jason.decode!(response)

      assert event_type == "greeting"
      assert data == %{"name" => "alice"}

      # But a greeting to Bob is not:

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for_bob(),
        [{"content-type", "application/json"}]
      )

      assert_raise Socket.Error, "timeout", fn ->
        socket_client |> Socket.Web.recv!(%{timeout: 100})
      end

      # We remove the subscription again:

      HTTPoison.put!(
        subscriptions_url,
        Jason.encode!(%{
          "subscriptions" => []
        }),
        [{"content-type", "application/json"}]
      )

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type, "data" => data} = Jason.decode!(response)

      assert event_type == "rig.subscriptions_set"
      assert data == []

      # After this, greetings to Alice are no longer forwarded:

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for_alice(),
        [{"content-type", "application/json"}]
      )

      assert_raise Socket.Error, "timeout", fn ->
        socket_client |> Socket.Web.recv!(%{timeout: 100})
      end
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

      # Establish a WS connection:

      {connection_id, socket_client} = new_ws_connection()
      subscriptions_url = "#{@external_url}/_rig/v1/connection/ws/#{connection_id}/subscriptions"

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

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type, "data" => data} = Jason.decode!(response)

      assert event_type == "rig.subscriptions_set"
      assert data == [%{"constraints" => [], "event_type" => "greeting"}]

      # A greeting without a name value is forwarded:

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_without_name(),
        [{"content-type", "application/json"}]
      )

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type} = Jason.decode!(response)

      assert event_type == "greeting"

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

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type, "data" => data} = Jason.decode!(response)

      assert event_type == "rig.subscriptions_set"
      assert data == [%{"constraints" => [%{"name" => "alice"}], "event_type" => "greeting"}]

      # ..the greeting without name is no longer forwarded:

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_without_name(),
        [{"content-type", "application/json"}]
      )

      assert_raise Socket.Error, "timeout", fn ->
        socket_client |> Socket.Web.recv!(%{timeout: 100})
      end
    end

    test "In case JWT is present in create subscription request it should automatically infer subscriptions from JWT." do
      # Set up the extractor configuration:

      set_extractor_config(%{
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

      # Establish a WS connection:

      {connection_id, socket_client} = new_ws_connection()
      subscriptions_url = "#{@external_url}/_rig/v1/connection/ws/#{connection_id}/subscriptions"
      token = generate_jwt("john.doe")

      HTTPoison.put!(
        subscriptions_url,
        Jason.encode!(%{
          "subscriptions" => []
        }),
        [
          {"content-type", "application/json"},
          {"authorization", token}
        ]
      )

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type, "data" => data} = Jason.decode!(response)

      assert event_type == "rig.subscriptions_set"
      assert data == [%{"constraints" => [%{"name" => "john.doe"}], "event_type" => "greeting"}]

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for("john.doe"),
        [{"content-type", "application/json"}]
      )

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type, "data" => data} = Jason.decode!(response)

      assert event_type == "greeting"
      assert data == %{"name" => "john.doe"}

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for("bob.doe"),
        [{"content-type", "application/json"}]
      )

      assert_raise Socket.Error, "timeout", fn ->
        socket_client |> Socket.Web.recv!(%{timeout: 100})
      end
    end

    test "In case JWT is present in initial connection request it should automatically infer subscriptions from JWT." do
      # Set up the extractor configuration:

      set_extractor_config(%{
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

      # Establish an SSE connection:
      token = generate_jwt("john.doe")

      {_connection_id, socket_client} = new_ws_connection(token)

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type, "data" => data} = Jason.decode!(response)

      assert event_type == "rig.subscriptions_set"
      assert data == [%{"constraints" => [%{"name" => "john.doe"}], "event_type" => "greeting"}]

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for("john.doe"),
        [{"content-type", "application/json"}]
      )

      {:text, response} = socket_client |> Socket.Web.recv!()
      %{"eventType" => event_type, "data" => data} = Jason.decode!(response)

      assert event_type == "greeting"
      assert data == %{"name" => "john.doe"}

      HTTPoison.post!(
        "#{@external_url}/_rig/v1/events",
        greeting_for("bob.doe"),
        [{"content-type", "application/json"}]
      )

      assert_raise Socket.Error, "timeout", fn ->
        socket_client |> Socket.Web.recv!(%{timeout: 100})
      end
    end
  end
end
