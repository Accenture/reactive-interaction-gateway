---
id: rig-dev-guide
title: Developer's Guide to the Reactive Interaction Gateway
sidebar_label: Developer's Guide
---

You'd like to mess with the code? Great! To get started, install Elixir and the Mix build tool on your machine. You can either follow the [instructions on the Elixir website](https://elixir-lang.org/install.html), or use [kiex](https://github.com/taylor/kiex) to install and manage Elixir runtimes. Kiex is recommended for development, because it allows you to jump to definitions inside the Elixir source code, plus you can checkout upcoming Elixir versions easily.

With Elixir installed, do this:

- Install dependencies with `mix deps.get`
- Start Phoenix endpoint with `mix phx.server`

RIG doesn't come with a status website, but if you like to you can check its health endpoint:

```bash
$ curl localhost:4000
{"message":"Route is not available"}
$ curl localhost:4000/health
OK
```

Additional notes:

- You can run tests with `mix test`. See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.
- When debugging multi-node features, it's helpful to run the (named) nodes in `iex` sessions
  using `iex --sname nodename -S mix`.

Our conventions are documented in [`guides/architecture/decisions/`](https://github.com/Accenture/reactive-interaction-gateway/blob/master/guides/architecture/decisions/). See [0001-record-architecture-decisions.md](https://github.com/Accenture/reactive-interaction-gateway/blob/master/guides/architecture/decisions/0001-record-architecture-decisions.md) for more details.

## Project Layout

Since 2.0, RIG uses the [umbrella project layout](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-apps.html#umbrella-projects), in order to make the code an easier read and adding/removing features simple. The following table should give you an idea how the code is organized:

Path | Umbrella&nbsp;App&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | What's in there
---- | ------------ | ---------------
apps/rig | `:rig` | The main application logic, including event filtering and distribution.
apps/rig_api | `:rig_api` | The internal API, built as a Phoenix app. The actual code triggered by a call to this API would typically be implemented in another umbrella app (for example, see `RigApi.MessageController`, which uses `RigOutboundGateway.send/1` underneath).
apps/rig_auth | `:rig_auth` | Code concerned with handling JWTs (or authentication, in general).
apps/rig_inbound_gateway | `:rig_inbound_gateway` | The externally facing HTTP server, built as a Phoenix app. It includes the reverse proxy, which forwards requests to back-end services as configured, as well as the Phoenix transports (e.g., WebSocket and SSE endpoints).
apps/rig_kafka | `:rig_kafka` | Kafka group consumer and producer.
apps/rig_outbound_gateway | `:rig_outbound_gateway` | Messages that are to be distributed to connected front-ends go through the outbound gateway.
apps/rig_tests | `:rig_tests` | Tests using multiple components and don't belong to certain sub-app.

While all apps share the same config, the convention is to put an app's config in its own config file and use the umbrella config file only for things that concern multiple apps.

Potential future umbrella apps:

Path | Umbrella&nbsp;App&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | What's in there
---- | ------------ | ---------------
apps/rig_admin_frontend | `:rig_admin_frontend` | An admin UI (again, a Phoenix app). For displaying and changing RIG's internal state, only `:rig_api` will be used. Ideas what could be offered: data about front-end connections, connections to other RIG nodes, message throughput, ..
apps/rig_monitor | `:rig_monitor` | Provides statistics to external monitoring applications like Prometheus, relying on `:rig_api` to gather the data.

### Adding/Removing an umbrella app

In order to add a new umbrella app, go to the `apps/` directory and use one of the mix generators. Make sure that the name of your app starts with `rig_` to uphold consistency. For example:

```bash
cd apps
mix new rig_my_new_app
```

Then go through the following:

- In the app's `mix.exs`, make sure to set `version` and `elixir` to the global versions; ideally just copy the respective parts from another app's `mix.exs` file.
- Update the table above with a description of what should go into the new app.
- Add/remove your app to/from the applications set in `rel/config.exs`.
- Add/remove your app to/from the `Dockerfile` with the relevant directories.

## Incrementing Elixir and OTP versions

To have the project use a newer Elixir version, make sure to change the following locations:

- `.travis.yml`
- `Dockerfile` (the `FROM` image tag)
- `mix.exs` (root level)

## Test Tags

We use `tag`s to group tests together. Often, it makes sense to assign more than one tag to a test case.

`@tag` | When to use it?
------ | ---------------
`:smoke` | Quick integration test that is designed to catch obvious integration problems.
