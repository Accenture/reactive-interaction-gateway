# 4. Use Rig.Config for global configuration

Date: 28/11/2017

## Status

Accepted

Supercedes [3. For config, prefer prefix over nesting and don't hide defaults in code](0003-for-config-prefer-prefix-over-nesting-and-don-t-hide-defaults-in-code.md)

## Context

The previous way of handling application configuration did not allow for a clean way
override values using environment variables. Such overrides are necessary, because
`config.exs` is evaluated at compile-time only. For instance, changing RIG's HTTP port
should not require the corresponding Docker image to be recompiled.

## Decision

We use [Confex](https://hexdocs.pm/confex/Confex.html) to make this more flexible.
Consider the following example for use in `config.exs`:

```elixir
config :rig, Rig.RateLimit,
  # Internal ETS table name (must be unique).
  table_name: :rate_limit_buckets,
  # Enables/disables rate limiting globally.
  enabled?: {:system, :boolean, "RATE_LIMIT_ENABLED", false},
  # If true, the remote IP is taken into account; otherwise the limits are per endpoint only.
  per_ip?: {:system, :boolean, "RATE_LIMIT_PER_IP", true},
  # The permitted average amount of requests per second.
  avg_rate_per_sec: {:system, :integer, "RATE_LIMIT_AVG_RATE_PER_SEC", 10_000},
  # The permitted peak amount of requests.
  burst_size: {:system, :integer, "RATE_LIMIT_BURST_SIZE", 5_000},
  # GC interval. If set to zero, GC is disabled.
  sweep_interval_ms: {:system, :integer, "RATE_LIMIT_SWEEP_INTERVAL_MS", 5_000}
```

Note that default values are given in `config.exs` and _never in the implementation_.

In `Rig.RateLimit`, this configuration would be accessible using the `Rig.Config` macro:

```elixir
  use Rig.Config,
    [:table_name, :enabled?, :per_ip?, :avg_rate_per_sec, :burst_size, :sweep_interval_ms]
```

The keyword list that supplied to the macro specifies the _required_ keys; that is,
their presence will be checked. Note that you can also validate the configuration
values yourself by using `:custom_validation`, for example:

```elixir
defmodule Rig.Kafka.MessageHandler do
  use Rig.Config, :custom_validation

  defp validate_config!(nil), do: validate_config!([])
  defp validate_config!(config) do
    {target_mod, target_fun} = Keyword.fetch!(config, :user_channel_name_mf)
    %{
      message_user_field: Keyword.fetch!(config, :message_user_field),
      user_channel_name: fn user -> apply(target_mod, target_fun, [user]) end
    }
  end

  ...
end
```

## Consequences

To the user, configuring RIG becomes easier. To the developer, using application
configuration within modules should be straightforward, with little to no boilerplate
code involved.
