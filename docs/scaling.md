---
id: scaling
title: Scaling
sidebar_label: Scaling
---

To run RIG in a more robust way you should use more nodes. To be able to form cluster from these nodes, set 3 environment variables `DISCOVERY_TYPE`, `DNS_NAME` and `NODE_HOST`. For `DISCOVERY_TYPE` we support currently `dns`. RIG will do auto-discovery every 5 seconds to find if there is any new node or node within the cluster is no longer alive. RIG guarantees distribution of API requests, event stream events and SSE/WS events.

You can leverage our [prepared configuration](https://github.com/Accenture/reactive-interaction-gateway/tree/master/deployment) for Kubernetes/Helm. Contains also more information about `DISCOVERY_TYPE`, `DNS_NAME` and `NODE_HOST` variables.

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

# Run from start with 3 nodes using Helm template -- (assuming you are in root directory)
helm install deployment/helm/reactive-interaction-gateway --set replicas=3
```
