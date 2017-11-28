# 3. For config, prefer prefix over nesting and don't hide defaults in code

Date: 18/08/2017

## Status

Superceded by [4. Use Rig.Config for global configuration](0004-use-rig-config-for-global-configuration.md)

## Context

There no agreed-upon way of handling application configuration. There are two issues this ADR aims to address.

### Issue 1: Nested keys

In `config.exs`, configuration keys can be nested by using a Keyword as value. Unfortunately, there is no built-in support for this nesting. For example:

```
Application.fetch_env!(:rig, :required_key)
```

will show a nice error, while

```
Application.fetch_env!(:rig, :required_key)[:required_subkey]
```

will simply return nil in case `:required_key` is present but `:required_subkey` is not.

### Issue 2: Default values

Some default values are defined where they are needed in the code, which is a problem once a key is used more than once. Also, defaults are no easily inspectable.

## Decision

* We prefer not to nest configuration keys; instead, we prefix them where it makes sense. For example, instead of `config :rig, :kafka, client_id: :rig_brod_client` we write `config :rig, kafka_client_id: :rig_brod_client`. This allows us to leverage the built-in methods (e.g., `Application.fetch_env!`), which produce sensible error messages in case required values are not defined.
* We always set default values in config.exs (in turn this means that we prefer `Application.fetch_env!` over `Application.get_env`). This way, it is easy to reason about default values, and using a default value in more than one place is not an issue.

## Consequences

We streamline the way configuration is done for the different parts of the application, which makes the configuration easier to read and reason about.
