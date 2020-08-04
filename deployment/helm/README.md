# Helm

`reactive-interaction-gateway` is an example [helm](https://helm.sh/) chart for Kubernetes, configured to run RIG in distributed mode.

## Configuration

### Docker image

You can use your own Docker image if it's based on original RIG Docker image.

```yaml
image: accenture/reactive-interaction-gateway
```

### NODE_HOST

IP used to set Node host for each node. Automatically taken from the environment variable ```NODE_HOST``` within the deployment configuration.

```yaml
- name: NODE_HOST
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
```

### DNS_NAME

Address upon which RIG will do DNS discovery. This has to point to Kubernetes headless service. `default` is namespaces where RIG runs.

```yaml
- name: DNS_NAME
  value: "reactive-interaction-gateway-service-headless.default.svc.cluster.local"
```

### Additional Configuration

When running in distributed mode, additional variables may be passed to the deployment in order to run the proper configuration. Updates to the helm chart can be made in ```helm/reactive-interaction-gateway/values.yaml```
Changes to these variables are required in most production circumstances.

For more information on configuration variables, please view the [Operator's Guide to the RIG](https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html)

## Running locally with Minikube

If you want to use local image (either original RIG or your own based on original RIG):

1. Switch to Minikube context `eval $(minikube docker-env)`
1. Build your image `docker build -t rig .`
1. Check `docker images` => new image should be listed there
1. Change the image name to `rig` in the [values file](reactive-interaction-gateway/values.yaml) (line 10)
1. Change `imagePullPolicy` to `Never` in the [values file](reactive-interaction-gateway/values.yaml) (line 12)


## Start RIG on Kubernetes

1. Make sure a tiller pod is running in the kube-system namespace ```kubectl get pods -n=kube-system```
1. `helm install deployment/helm/reactive-interaction-gateway` (assuming you are in root directory)
1. `kubectl get pod,svc` should list a running RIG pod and two services

**Note:** Services should communicate with `reactive-interaction-gateway-service` which is reachable within Kubernetes cluster (but not outside of server) on port 4000 (by default). This service will load balance requests amongst replicas. Changes to the service can by done by modify the configuration in values.yaml to allow external communication with ``` type:LoadBalancer```

## Scaling

1. Get the name of the deployment ```kubectl get deployments```
1. Scale the deployment and create multiple pods ```kubectl scale deployment/<deployment_name> --replicas <replicas>```
1. ```kubectl get pods``` should list new pods automatically connected to RIG cluster

You can also inspect logs of pods ```kubectl logs <pod_name>``` to see how they automatically rebalance Kafka consumers (if you are using Kafka) and adapt Proxy APIs from other nodes.
