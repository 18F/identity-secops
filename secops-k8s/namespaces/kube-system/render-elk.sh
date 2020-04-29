#!/bin/sh

helm repo add elastic https://helm.elastic.co
helm repo update

helm template elasticsearch-logging elastic/elasticsearch --namespace kube-system > elasticsearch.yml
helm template kibana elastic/kibana --namespace kube-system > kibana.yml
helm template logstash elastic/logstash -f elk-config/logstash-values.yml --namespace kube-system > logstash.yml
helm template filebeat elastic/filebeat --namespace kube-system > filebeat.yml

