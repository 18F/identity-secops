#!/bin/sh
# 
# We are using the elastic.co helm charts to generate our deployment.
# Run this script to update to the latest/greatest and then check it in.
#

helm repo add elastic https://helm.elastic.co
helm repo update

helm template elasticsearch-logging elastic/elasticsearch > ../clusterconfig/base/logging-elasticsearch.yml
helm template kibana elastic/kibana > ../clusterconfig/base/logging-kibana.yml
helm template logstash elastic/logstash -f logstash-values.yml > ../clusterconfig/base/logging-logstash.yml
helm template filebeat elastic/filebeat --namespace kube-system > logging-filebeat.yml

