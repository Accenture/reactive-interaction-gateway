# Distributed deployment

Reactive Interaction Gateway (RIG) uses [Peerage library](https://github.com/mrluc/peerage) to do discovery in distributed mode (production Distillery release).

**Note:** If you don't care about distributed mode and don't want to do discovery, follow just `General configuration` section and ignore rest of the text.

## Configuration

### General configuration

1. Node host - Every node in cluster needs to be discoverable by other nodes. For that Elixir/Erlang uses so called `long name` or `short name`. We are using `long name` which is formed in the following way `app_name@node_host`. `app_name` is in our case set to `rig`, but `node_host` is taken from environment variable `NODE_HOST`. This can be either IP or container alias or whatever that is routable in network by other nodes.

1. Node cookie - Nodes in Erlang cluster use cookies as a form of authorization/authentication between them. Only nodes with the same cookie can communicate together. It should be ideally some generated hash, set it to `NODE_COOKIE` environment variable.

### DNS discovery

RIG currently supports distributed deployment via DNS discovery. To make it work, you need to set two things:

1. Discovery type - Currently RIG supports only DNS discovery. To use DNS, set `DISCOVERY_TYPE` to `dns`.

1. DNS name (address) - Address where peerage will do discovery for Node host addresses. Value is taken from environment variable `DNS_NAME`.

DNS discovery is executed every 5 seconds.

### Additional configuration

When running in distributed mode, additional variables may be passed to the deployment in order to run the proper configuration.
Changes to these variables are required in most production circumstances.

For more information on configuration variables, please view the [Operators Guide to the RIG](https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html)
