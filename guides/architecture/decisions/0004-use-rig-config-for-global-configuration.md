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
config :rig, RigInboundGateway.ApiProxy.Base,
  recv_timeout: {:system, :integer, "PROXY_RECV_TIMEOUT", 5_000}
```

Note that default values are given in `config.exs` and _never in the implementation_.

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
