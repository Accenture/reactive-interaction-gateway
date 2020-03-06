defmodule Rig.EventFilter.ServerTest do
  @moduledoc false
  use ExUnit.Case, async: false
  doctest Rig.EventFilter.Server

  alias Rig.EventFilter
  alias Rig.EventFilter.Server
  alias Rig.Subscription
  alias RigCloudEvents.CloudEvent

  defp register_subscription_with_event_filter(subscription) do
    test_pid = self()

    # Set up the subscription:
    EventFilter.refresh_subscriptions([subscription], [], fn ->
      send(test_pid, :subscriptions_refreshed)
    end)

    # wait for it..
    assert_receive :subscriptions_refreshed, 1_000

    # Should be active now!
  end

  test "subscribe & receive an event" do
    event_type = "test.event"
    field_config = %{}
    subscription = Subscription.new!(%{event_type: event_type})

    event =
      CloudEvent.parse!(%{
        "specversion" => "0.2",
        "type" => event_type,
        "source" => "test",
        "id" => "1"
      })

    opts = [debug?: true, subscription_ttl_s: 0]
    {:ok, filter_pid} = Server.start_link(event_type, field_config, opts)

    register_subscription_with_event_filter(subscription)
    EventFilter.forward_event(event, "source_type", "topic")
    EventFilter.forward_event(event, "source_type", "topic")

    assert_receive ^event
    assert_receive ^event

    # No longer receive an event for timed-out subscriptions after :cleanup:
    simulate_cleanup(filter_pid)
    EventFilter.forward_event(event, "source_type", "topic")
    refute_receive ^event

    :ok = GenServer.stop(filter_pid)
  end

  defp simulate_cleanup(pid) do
    pid
    |> :sys.get_state()
    |> Server.remove_expired_records()
  end

  test "receive only events that satisfy constraints" do
    event_type = "person.create"

    field_config = %{
      "age" => %{
        "stable_field_index" => 1,
        "event" => %{"json_pointer" => "/data/age"}
      },
      "name" => %{
        "stable_field_index" => 0,
        "event" => %{"json_pointer" => "/data/name"}
      }
    }

    name_is_joe = %{"name" => "joe"}
    age_is_30 = %{"age" => 30}

    joe_subscription = Subscription.new!(%{event_type: event_type, constraints: [name_is_joe]})

    joe_and_30_subscription =
      Subscription.new!(%{
        event_type: event_type,
        constraints: [Map.merge(name_is_joe, age_is_30)]
      })

    base_event = %{"specversion" => "0.2", "type" => event_type, "source" => "test"}

    joe_20_event =
      base_event
      |> Map.merge(%{"id" => 1, "data" => %{"name" => "joe", "age" => 20, "x" => "x"}})
      |> CloudEvent.parse!()

    joe_30_event =
      base_event
      |> Map.merge(%{"id" => 2, "data" => %{"name" => "joe", "age" => 30, "x" => "x"}})
      |> CloudEvent.parse!()

    bob_30_event =
      base_event
      |> Map.merge(%{"id" => 3, "data" => %{"name" => "bob", "age" => 30, "x" => "x"}})
      |> CloudEvent.parse!()

    joe_noage_event =
      base_event
      |> Map.merge(%{"id" => 4, "data" => %{"name" => "joe", "age" => nil, "x" => "x"}})
      |> CloudEvent.parse!()

    specs = [
      {joe_subscription, joe_20_event, :match},
      {joe_subscription, joe_30_event, :match},
      {joe_subscription, joe_noage_event, :match},
      {joe_subscription, bob_30_event, :no_match},
      {joe_and_30_subscription, joe_20_event, :no_match},
      {joe_and_30_subscription, joe_30_event, :match},
      {joe_and_30_subscription, joe_noage_event, :no_match},
      {joe_and_30_subscription, bob_30_event, :no_match}
    ]

    for {subscription, event, match_expectation} <- specs do
      {:ok, filter_pid} = Server.start_link(event_type, field_config)

      register_subscription_with_event_filter(subscription)
      EventFilter.forward_event(event, "source_type", "topic")

      case match_expectation do
        :match -> assert_receive ^event
        :no_match -> refute_receive ^event
      end

      :ok = GenServer.stop(filter_pid)
    end
  end

  test "Allows refreshing the field config" do
    empty_field_config = %{}

    greeting_with_name_field_config = %{
      "name" => %{
        "stable_field_index" => 0,
        "event" => %{"json_pointer" => "/data/name"}
      }
    }

    # We start the server using an empty field config:
    event_type = "greeting-29-08-2019"
    {:ok, filter_pid} = Server.start_link(event_type, empty_field_config)

    # Since no field is configured, any constraints are ignored:
    name_is_joe = %{"name" => "joe"}

    greetings_to_joe_subscription =
      Subscription.new!(%{event_type: event_type, constraints: [name_is_joe]})

    register_subscription_with_event_filter(greetings_to_joe_subscription)

    base_event = %{"specversion" => "0.2", "type" => event_type, "source" => "test"}

    greeting_to_joe =
      base_event |> Map.merge(%{"id" => 1, "data" => %{"name" => "joe"}}) |> CloudEvent.parse!()

    greeting_to_sam =
      base_event |> Map.merge(%{"id" => 2, "data" => %{"name" => "sam"}}) |> CloudEvent.parse!()

    # Even though the greeting is for Sam and not for Joe, we receive it:
    EventFilter.forward_event(greeting_to_sam, "source_type", "topic")
    assert_receive ^greeting_to_sam

    # Let's load the proper field config now:
    GenServer.call(filter_pid, {:reload_configuration, greeting_with_name_field_config})

    # Without touching the subscriptions, there is no change:
    EventFilter.forward_event(greeting_to_sam, "source_type", "topic")
    assert_receive ^greeting_to_sam

    # But after refreshing the subscriptions, a greeting to Sam is no longer forwarded:
    register_subscription_with_event_filter(greetings_to_joe_subscription)
    # wait for genserver cast
    :sys.get_state(filter_pid)
    EventFilter.forward_event(greeting_to_sam, "source_type", "topic")
    refute_receive ^greeting_to_sam

    # ...but a greeting to Joe still is:
    EventFilter.forward_event(greeting_to_joe, "source_type", "topic")
    assert_receive ^greeting_to_joe

    :ok = GenServer.stop(filter_pid)
  end
end

defmodule Rig.EventFilter.TableModificationTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Rig.EventFilter.Server, as: SUT

  describe "Wildcards" do
    test "are not applied to an empty ETS table" do
      table = new_table()
      SUT.add_wildcards_to_table(table, 0, 1)
      assert :ets.info(table)[:size] == 0
      :ets.delete(table)
    end

    test "adds wildcards to each row in a non-empty ETS table" do
      table = new_table()
      insert_row(table, [])
      SUT.add_wildcards_to_table(table, 0, 1)
      assert :ets.info(table)[:size] == 1
      :ets.delete(table)
    end
  end

  defp new_table, do: :ets.new(:test, [:bag, :public])

  defp insert_row(table, fields) do
    pid = self()
    exp = 123
    row = ([pid, exp] ++ fields) |> List.to_tuple()
    :ets.insert(table, row)
    table
  end
end
