helm install prometheus stable/prometheus --set server.global.scrape_interval="10s"
helm install grafana stable/grafana -f datasource-helm.yaml


echo "Grafana password: $(kubectl get secret grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)"
echo "Prometheus: kubectl port-forward $(kubectl get pods -l 'app=prometheus,component=server' -o jsonpath='{.items[0].metadata.name}') 9090"
echo "Grafana: kubectl port-forward $(kubectl get pods -l 'app=grafana,release=grafana' -o jsonpath='{.items[0].metadata.name}') 3000"

./start_run1.sh
#./start_run2.sh
#./start_run6.sh

#grafana and prometheus have to be uninstalled