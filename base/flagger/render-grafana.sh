#!/bin/sh
# 
# We are using the flagger helm charts to generate our deployment.
# Run this script to update to the latest/greatest and then check it in.
#

helm repo add flagger https://flagger.app
helm repo update
kubectl config set-context --current --namespace=flagger-system

helm template grafana flagger/grafana -f grafana-values.yml > flagger-grafana.yml

