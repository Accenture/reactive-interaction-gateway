defmodule Rig.EventFilter do
  @moduledoc """
  Check point between connection processes and event sources.

  # Event Subscriptions

  The EventFilter is a central component to RIG's event subscription implementation. In
  order to understand their role, we first take a look at events and event types.

  ## Events and event types

  We're going to use the [Cloud Events Spec](https://github.com/cloudevents/spec)
  wherever possible (see `Rig.CloudEvent`). For example, incoming events are expected
  to feature an "eventType" field.

  An "official" example of such an event type is `com.github.pull.create`. We can infer
  the following properties:

  - Event types use reverse-dns notation, which means the type name contains
    parent-to-child relations defined by the dot character.
  - Event types are likely going to be unrelated to specific entities or (user)
    sessions. For example, for a repository "my-org/my-repo", we do not expect to see
    events like `com.github.pull.create.my-org/my-repo`; instead, the repository ID is
    likely to be found in the CloudEvent's data field (as there is no "subject"-like
    field mentioned in the spec).

  Following those observations/assumptions, we assume to events that look similar to
  the following (based on Github's [get a single
  pull request](https://developer.github.com/v3/pulls/#get-a-single-pull-request) API):

  ```json
  {
    "cloudEventsVersion": "0.1",
    "eventType": "com.github.pull.create",
    "source": "/desktop-app",
    "eventID": "A234-1234-1234",
    "eventTime": "2018-04-05T17:31:00Z",
    "data": {
      "assignee": {
        "login": "octocat",
      },
      "head": {
        "repo": {
          "full_name": "octocat/Hello-World",
        },
      },
      "base": {
        "repo": {
          "full_name": "octocat/Hello-World",
        },
      },
    }
  }
  ```

  ## Extractors

  Because of this, RIG's internal subscriptions cannot rely on the event type only. RIG
  is built for routing events to users' devices or sessions, so it must also have a
  notion of those things built into the subscription mechanism.

  The idea: introduce "extractors" that can extract information from an event, and
  allow subscriptions to match against that extracted information.

  Let's take a look at an example:

  - Assume there is an event type `com.github.pull.create`;
  - Assume the user is interested in events that refer to the "octocat/Hello-World";
  - Assume the user only interested in new pull requests assigned to the "octocat" user;
  - We start RIG with an _extractor configuration_ that uses
    [JSON Pointer](https://tools.ietf.org/html/rfc6901) to find data:

  ```yaml
  extractors:
    com.github.pull.create:
      assignee:
        # "assignee" is the field name that can be referred to in the subscription request
        # (see subscription request example below).
        # Each field has a field index value that needs to remain the same unless all RIG
        # nodes are stopped and restarted. This can be compared to gRPC field numbers and
        # the same rule of thumb applies: always append fields and never reuse a field
        # index/number.
        stable_field_index: 0
        # JWT values take precedence over values given in a subscription request:
        jwt:
          # Describes where to find the value in the JWT:
          json_pointer: /username
        event:
          # Describes where to find the value in the event:
          json_pointer: /data/assignee/login

      head_repo:
        stable_field_index: 1
        # This is extracted from subscription requests, rather than in the JWT. In the
        # request body the field is referred to by name, so a `json_pointer` is required
        # for the event only:
        event:
          json_pointer: /data/head/repo/full_name

      base_repo:
        stable_field_index: 2
        event:
          json_pointer: /data/base/repo/full_name
  ```

  The extractor configuration is picked up by the Filter Supervisor
  `Rig.EventFilter.Sup`, which applies event-type specific configuration to the
  respective Event Filter process (GenServer) `Rig.EventFilter.Server`.

  ## Subscriptions

  Note: see `Rig.Subscription`.

  The frontend sends a subscription that refers to those fields:

  ```json
  {
    "eventType": "com.github.pull.create",
    "oneOf": [
      { "head_repo": "octocat/Hello-World" },
      { "base_repo": "octocat/Hello-World" }
    ]
  }
  ```

  The frontend receives the event outlined above because one of the constraint defined
  under `oneOf` is fulfilled. Note that within each constraint object, all fields must
  match, so the constraints are defined in
  [conjunctive normal form](https://en.wikipedia.org/wiki/Conjunctive_normal_form).

  If a JSON Pointer expression returns more than one value, there is a match if, and
  only if, the target value is included in the JSON Pointer result list.

  A subscription request may contain multiple subscriptions:

  ```json
  {
    "subscriptions": [
      {
        "eventType": "com.github.pull.create",
        "oneOf": [
          { "head_repo": "octocat/Hello-World" },
          { "base_repo": "octocat/Hello-World" }
        ]
      }
    ]
  }
  ```

  In this example, the subscription's constraints are fulfilled when either of the `head_repo` and `base_repo` fields match. If the subscription should only apply to cases where _both_ fields match, it should look like this instead:

  ```json
  {
    "subscriptions": [
      {
        "eventType": "com.github.pull.create",
        "oneOf": [
          { "head_repo": "octocat/Hello-World", "base_repo": "octocat/Hello-World" }
        ]
      }
    ]
  }
  ```

  ### Implementation

  Note: see `Rig.EventFilter.Server` and `Rig.EventFilter.MatchSpec.SubscriptionMatcher`.

  Matching relies on ETS match specs - subscriptions are kept in an ETS table, for each
  event type. The tables contain all key/value pairs as defined in the extractor for
  the event type; they contain the values as defined in the subscription. If a value is
  not set in a subscription, the missing value is set to nil. For example, the
  subscription above would be reflected in two records:

  ```elixir
  {connection_pid, {:assignee, "octocat"}, {:head_repo, "octocat/Hello-World"}, {:base_repo, nil}}
  {connection_pid, {:assignee, "octocat"}, {:head_repo, nil}, {:base_repo, "octocat/Hello-World"}}
  ```

  This structure allows for very efficient matching. There is also a dedicated table
  per event type, so ownership is easy and there are no concurrent requests per table.
  At the time of writing, the default limit on the number of ETS tables is 1400 per
  node, but this can be changed using `ERL_MAX_ETS_TABLES`. If that ever becomes
  impractical, putting all subscriptions in a single table should work just as well.

  The processes consuming events from Kafka and Kinesis are not the right place for
  running any filtering or routing logic, as we need them to be as fast as possible.
  Instead, for each event type there is one process on each node, enabling the consumer
  processes to quickly hand-off events by looking at only the event type field. Those
  "filter" processes own their event-type specific ETS table. For any given event, they
  can use their ETS table to obtain the list of processes to send the events to.

  ```plain
                                                               +
                                                      Node A   |   Node B
                                                               |
                                                               |
                                                               |
                        +                                      |                            +
                        |                                      |                            |
                        | events                               |                            | events
                        |                                      |                            |
                        |                                      |                            |
              +---------v----------+                           |                  +---------v----------+
              |                    |                           |                  |                    |
              |   Kafka Consumer   |                           |                  |   Kafka Consumer   |
              |                    |                           |                  |                    |
              +---+-------------+--+                           |                  +---+-------------+--+
                  |             |                              |                      |             |
                  |             |                              |                      |             |
   foo.bar events |             | foo.baz events               |       foo.bar events |             | foo.baz events
                  |             |                              |                      |             |
                  |             |                              |                      |             |
  +-----------------v---+     +---v-----------------+          |    +-----------------v---+     +---v-----------------+
  |                     |     |                     |          |    |                     |     |                     |
  |  Filter             |     |  Filter             |          |    |  Filter             |     |  Filter             |
  |  eventType=foo.bar  |     |  eventType=foo.baz  |          |    |  eventType=foo.bar  |     |  eventType=foo.baz  |
  |                     |     |                     |          |    |                     |     |                     |
  +---------------------+     +----+-------------+--+          |    +---------------------+     +---+-------------+---+
                                 |             |               |                                    |             |
                                 |             |               |                                    |             |
                                 |             |               |                                    |             |
                            foo.bar events that|       <----------------------------------------------------------+
                            satisfy the connections'           |                                    |
                            subscription constraints   <--------------------------------------------+
                                 |             |               |
                                 |             |               |       A connection subscribes to all filters (periodically),
                      +----------v---+     +---v----------+    |       using the filters' process group. For incoming events,
                      |              |     |              |    |       the filter processes check against all subscription
                      |  WebSocket   |     |     SSE      |    |       constraints and forward the events that match to the
                      |  connection  |     |  connection  |    |       respective connection processes (using the pids stored
                      |              |     |              |    |       in the filter's ETS table).
                      +--------------+     +--------------+    +
  ```

  Processes, process groups and lifecycles:

  - Consumer processes (Kafka and Kinesis)
    - permanent
  - Filter processes
    - The consumer processes have to start filter processes on demand, on their
      respective node.
    - Filter process stop themselves after not receiving messages for some time.
    - Filter processes join process groups, such that for each event type there is one
      such group.
  - Connection processes
    - are tied to the connection itself
  - Subscription entries in the filters' ETS table..
    - are created and refreshed periodically by the connection process, which sends
      the request to all filter processes in the event-type group. The HTTP call that
      creates the subscription does not directly call a filter process, but instead
      informs the connection process itself of the new subscription, which in turn
      registers with the respective filter processes.
    - have a per record time-to-live, used to keep the data current. If a connection
      process dies, the subscription records will no longer be refreshed and get
      removed eventually.

  """
  alias Rig.EventFilter.Server, as: Filter
  alias Rig.EventFilter.Sup, as: FilterSup
  alias Rig.Subscription
  alias RigCloudEvents.CloudEvent

  # alias RigMetrics.SubscriptionsMetrics

  @doc """
  Refresh an existing subscription.

  Typically called periodically by socket processes for each of their subscriptions.
  Registers the subscription with all Filter Supervisors on all nodes, using a PG2
  process group to find them.

  """
  @type done_callback :: (() -> nil)

  @callback refresh_subscriptions([Subscription.t()], [Subscription.t()], done_callback) ::
              :ok
  def refresh_subscriptions(subscriptions, prev_subscriptions, done_callback \\ nil) do
    # There is one Filter Supervisor per node. Each of those supervisors forwards the
    # subscriptions to the right Filter processes on the node they're located on.

    subscriber = self()

    for pid <- FilterSup.processes() do
      GenServer.cast(
        pid,
        {:refresh_subscriptions, subscriber, subscriptions, prev_subscriptions, done_callback}
      )

      # increase Prometheus metric with a subscription
      SubscriptionsMetrics.set_subscriptions(length(subscriptions))
    end

    :ok
  end

  # ---

  @callback forward_event(Cloudevents.t()) :: :ok
  @spec forward_event(Cloudevents.t()) :: :ok
  def forward_event(event) when is_struct(event) do
    event_type = CloudEvent.type!(event)
    # On any node, there is only one Filter process for a given event type, or none, if
    # there are no subscriptions for the event type.
    with name <- Filter.process(event_type) do
      GenServer.cast(name, event)
    end

    :ok
  end

  # ---

  @doc ~S"""
  Reloads the configuration on all nodes.
  """
  @spec reload_config_everywhere() :: :ok
  def reload_config_everywhere do
    # Calls the registered Filter Supervisor on all connected nodes:
    for pid <- FilterSup.processes() do
      Task.async(fn -> GenServer.call(pid, :reload_config) end)
    end
    |> Enum.each(&Task.await/1)

    :ok
  end
end
