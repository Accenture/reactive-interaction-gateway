# Running RIG on Kubernetes

## Kubectl

```bash
kubectl apply -f kubectl/rig.yaml
```

## Helm

### Version 2

```bash
cd helm2
# dry run to verify that everything is ok
helm install --name=rig reactive-interaction-gateway --dry-run
# install
helm install --name=rig reactive-interaction-gateway
```

### Version 3

```bash
cd helm3
# dry run to verify that everything is ok
helm install rig reactive-interaction-gateway --dry-run
# install
helm install rig reactive-interaction-gateway
```

## Communication

Both `kubectl` and `helm` deploy bunch of Kubernetes resources:

- deployment - manages pod(s)
- service - provides the main communication point for other applications
- headless service - takes care of DNS discovery used internally

To allow external communication (outside of your cluster) do:

```bash
# both helm versions
helm upgrade --set service.type=LoadBalancer rig reactive-interaction-gateway
# for kubectl update kubectl/rig.yaml to use a service of type LoadBalancer instead of ClusterIP
```

## Scaling

Scale the deployment and create multiple pods

```bash
helm upgrade --set service.type=LoadBalancer --set replicaCount=<replicas> rig reactive-interaction-gateway
# or
kubectl scale deployment/<deployment_name> --replicas <replicas>
```

You can also inspect the logs of the pods with `kubectl logs <pod_name>` to see how they automatically re-balance Kafka consumers (if you are using Kafka) and adapt Proxy APIs from other nodes.

## Configuration

### Node host

Every node in cluster needs to be discoverable by other nodes. For that Elixir/Erlang uses so called `long name` or `short name`. We are using `long name` which is formed in the following way `app_name@node_host`. `app_name` is in our case set to `rig` and `node_host` is taken from environment variable `NODE_HOST`. This can be either IP or container alias or whatever that is routable in network by other nodes.

We are using the pod IP with:

```yaml
- name: NODE_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
```

### Node cookie

Nodes in Erlang cluster use cookies as a form of authorization/authentication between them. Only nodes with the same cookie can communicate together. Ideally, it is some generated hash, that's why we recommend adapting `NODE_COOKIE` environment variable in the `values.yaml`.

### Additional configuration

You can configure bunch of environment variables, please check the [Operator's Guide](https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html).

## Cleanup

```bash
# kubectl
kubectl delete -f kubectl/rig.yaml

# Helm v3
helm uninstall rig

# Helm v2
helm delete --purge rig
```
