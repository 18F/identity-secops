#!/bin/sh
# 
# We are using the elastic.co helm charts to generate our deployment.
# Run this script to update to the latest/greatest and then check it in.
#

helm repo add elastic https://helm.elastic.co
helm repo update
kubectl config set-context --current --namespace=elk

helm template elasticsearch-logging elastic/elasticsearch -f elasticsearch-values.yml > logging-elasticsearch.yml
helm template kibana elastic/kibana > logging-kibana.yml
helm template logstash elastic/logstash -f logstash-values.yml > logging-logstash.yml

kubectl config set-context --current --namespace=kube-system
helm template filebeat elastic/filebeat -f filebeat-values.yml --namespace kube-system > filebeat/logging-filebeat.yml

