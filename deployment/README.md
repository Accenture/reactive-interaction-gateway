# Distributed deployment

Reactive Interaction Gateway (RIG) uses [Peerage library](https://github.com/mrluc/peerage) to do discovery in distributed mode (production Distillery release).

## Kubectl

```bash
kubectl apply -f kubectl/rig.yaml
```

## Helm

### Version 2

```bash
# dry run to verify that everything is ok
helm install --name=rig reactive-interaction-gateway --dry-run
# install
helm install --name=rig reactive-interaction-gateway
```

### Version 3

```bash
# dry run to verify that everything is ok
helm install rig reactive-interaction-gateway --dry-run
# install
helm install rig reactive-interaction-gateway
```

## Communication

Both `kubectl` and `helm` deploy bunch of Kubernetes resources:

- deployment - creates also pod(s)
- service - provides the main communication point for other applications -- `rig-reactive-interaction-gateway`
- headless service - takes care of DNS discovery

To allow external communication (outside of your cluster) do:

```bash
# both helm versions
helm upgrade --set service.type=LoadBalancer rig reactive-interaction-gateway
# for kubectl update kubectl/rig.yaml:12 to LoadBalancer
```

## Scaling

1. Get the name of the deployment `kubectl get deployments`
2. Scale the deployment and create multiple pods `kubectl scale deployment/<deployment_name> --replicas <replicas>`
3. `kubectl get pods` should list new pods automatically connected to RIG cluster

You can also inspect logs of pods `kubectl logs <pod_name>` to see how they automatically re-balance Kafka consumers (if you are using Kafka) and adapt Proxy APIs from other nodes.

## Configuration

### Node host

Every node in cluster needs to be discoverable by other nodes. For that Elixir/Erlang uses so called `long name` or `short name`. We are using `long name` which is formed in the following way `app_name@node_host`. `app_name` is in our case set to `rig` and `node_host` is taken from environment variable `NODE_HOST`. This can be either IP or container alias or whatever that is routable in network by other nodes.

In Kubernetes world it can be set like this:

```yaml
- name: NODE_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
```

### Node cookie

Nodes in Erlang cluster use cookies as a form of authorization/authentication between them. Only nodes with the same cookie can communicate together. It should be ideally some generated hash, set it to the `NODE_COOKIE` environment variable.

### DNS discovery

RIG currently supports distributed deployment via DNS discovery. To make it work, you need to set two environment variables:

1. Discovery type - Currently, RIG supports only `dns` discovery. To use DNS, set the `DISCOVERY_TYPE` to `dns`.

2. DNS name (address) - Address where peerage will do a discovery for Node host addresses. Value is taken from the environment variable `DNS_NAME`.

DNS discovery is executed every 5 seconds.

In Kubernetes world it can be set like this:

```yaml
- name: DISCOVERY_TYPE
  value: dns
- name: DNS_NAME
  value: "reactive-interaction-gateway-service-headless.default.svc.cluster.local"
```

> `default` is Kubernetes namespace.

### Additional configuration

You can configure bunch of environment variables, please check the [Operator's Guide](https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html).
