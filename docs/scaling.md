---
id: scaling
title: Scaling
sidebar_label: Scaling
---

To run RIG in a more robust way you should use more nodes. To be able to form cluster from these nodes, check our [deployment guide](https://github.com/Accenture/reactive-interaction-gateway/tree/master/deployment). Mentioned deployment guide also provides configuration for `kubectl` and `helm` (v2 and v3). RIG guarantees distribution of API requests, event stream events and SSE/WS events.

Even though it's possible to run RIG anywhere, we recommend to use Kubernetes.

```bash
# Increase number of nodes in Kubernetes cluster to 3
# After few seconds already running RIG will auto-discover new nodes and form the cluster, this means:
# - automatic synchronization of APIs across the nodes - notice logs with API synchronization
# - redistribution of Kafka/Kinesis partitions - notice logs with partitions rebalancing
# - blacklist state synchronization
# - SSE/WS synchronization
#
# From this point entire communication will be distributed between the nodes
kubectl scale deployment/reactive-interaction-gateway --replicas 3

# Start right away with 3 nodes using Helm template -- (assuming you are in the deployment directory)
helm repo add accenture https://Accenture.github.io/reactive-interaction-gateway
# Helm v3
helm install --set replicaCount=3 rig accenture/reactive-interaction-gateway
# Helm v2
helm install --set replicaCount=3 --name=rig accenture/reactive-interaction-gateway
```
