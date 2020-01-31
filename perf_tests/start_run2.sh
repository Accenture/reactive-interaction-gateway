#!/bin/bash

set -m

helm install kafka incubator/kafka -f ./kafka/chart/values.yml

kubectl wait --for=condition=Ready --timeout=5m pod/kafka-zookeeper-0
kubectl wait --for=condition=Ready --timeout=5m pod/kafka-zookeeper-1
kubectl wait --for=condition=Ready --timeout=5m pod/kafka-zookeeper-2
kubectl wait --for=condition=Ready --timeout=5m pod/kafka-0

helm install rig ./rig/chart

cd src/run2
docker-compose build

chmod +x start_k8s.sh
./start_k8s.sh

kubectl wait --for=condition=Ready --timeout=5m "pod/$(kubectl get pods -l 'app=run2-clients-deployment' -o jsonpath='{.items[0].metadata.name}')"
kubectl wait --for=condition=Ready --timeout=5m "pod/$(kubectl get pods -l 'app=run2-loader-deployment' -o jsonpath='{.items[0].metadata.name}')"

echo "Starting log collection..."

cd ../..

timeout 10m bash <<EOT
kubectl logs "$(kubectl get pods -l 'app=run2-clients-deployment' -o jsonpath='{.items[0].metadata.name}')" -f > run2.client.log
EOT

helm uninstall rig
helm uninstall kafka
helm uninstall run2-clients
helm uninstall run2-loader