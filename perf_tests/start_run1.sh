#!/bin/bash

set -m

helm install kafka incubator/kafka -f ./kafka/chart/values.yml

kubectl wait --for=condition=Ready --timeout=5m pod/kafka-zookeeper-0
kubectl wait --for=condition=Ready --timeout=5m pod/kafka-zookeeper-1
kubectl wait --for=condition=Ready --timeout=5m pod/kafka-zookeeper-2
kubectl wait --for=condition=Ready --timeout=5m pod/kafka-0

helm install rig ./rig/chart

cd src/run1
docker-compose build

chmod +x start_k8s.sh
./start_k8s.sh

kubectl wait --for=condition=Ready --timeout=5m "pod/$(kubectl get pods -l 'app=run1-clients-deployment' -o jsonpath='{.items[0].metadata.name}')"
kubectl wait --for=condition=Ready --timeout=5m "pod/$(kubectl get pods -l 'app=run1-loader-deployment' -o jsonpath='{.items[0].metadata.name}')"

echo "Starting log collection..."

cd ../..

timeout 10m bash <<EOT
kubectl logs "$(kubectl get pods -l 'app=run1-clients-deployment' -o jsonpath='{.items[0].metadata.name}')" -f > run1.client.log
EOT

helm uninstall rig
helm uninstall kafka
helm uninstall run1-clients
helm uninstall run1-loader