# Running RIG on Kubernetes

The easiest way to deploy RIG is using Helm:

```shell
helm repo add accenture https://Accenture.github.io/reactive-interaction-gateway
# Helm v3
helm install rig accenture/reactive-interaction-gateway
# Helm v2
helm install --name=rig accenture/reactive-interaction-gateway-helm-v2
```

Check out the [Helm v2 README](./reactive-interaction-gateway-helm-v2/README.md) or [Helm v3 README](./reactive-interaction-gateway/README.md) and [Operator's Guide](https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html) for more information on configuring RIG.

## Deploy with kubectl

> This deployment is not recommended as lots of configurations is hard coded

```bash
kubectl apply -f kubectl/rig.yaml
```

## Some Additional information

### Communication

Both `kubectl` and `helm` deploy bunch of Kubernetes resources:

- deployment - manages pod(s)
- service - provides the main communication point for other applications
- headless service - takes care of DNS discovery used internally

To allow external communication (outside of your cluster) do:

```bash
helm upgrade --set service.type=LoadBalancer rig accenture/reactive-interaction-gateway
# for kubectl update kubectl/rig.yaml to use a service of type LoadBalancer instead of ClusterIP
```

### Scaling

Scale the deployment and create multiple pods

```bash
helm upgrade --set replicaCount=<replicas> rig accenture/reactive-interaction-gateway
# or
kubectl scale deployment/<deployment_name> --replicas <replicas>
```

You can also inspect the logs of the pods with `kubectl logs <pod_name>` to see how they automatically re-balance Kafka consumers (if you are using Kafka) and adapt Proxy APIs from other nodes.

### Configuration

#### Node host

Every node in cluster needs to be discoverable by other nodes. For that Elixir/Erlang uses so called `long name` or `short name`. We are using `long name` which is formed in the following way `app_name@node_host`. `app_name` is in our case set to `rig` and `node_host` is taken from environment variable `NODE_HOST`. This can be either IP or container alias or whatever that is routable in network by other nodes.

We are using the pod IP with:

```yaml
- name: NODE_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
```

#### Node cookie

Nodes in Erlang cluster use cookies as a form of authorization/authentication between them. Only nodes with the same cookie can communicate together. Ideally, it is some generated hash, that's why we recommend adapting `NODE_COOKIE` environment variable in the `values.yaml`.

#### Additional configuration

You can configure bunch of environment variables, please check the [Helm v2 README](./reactive-interaction-gateway-helm-v2/README.md) or [Helm v3 README](./reactive-interaction-gateway/README.md) and [Operator's Guide](https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html).

## Cleanup

```bash
# kubectl
kubectl delete -f kubectl/rig.yaml

# Helm v3
helm uninstall rig

# Helm v2
helm delete --purge rig
```
