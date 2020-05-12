#!/bin/sh
# 
# We are using the elastic.co helm charts to generate our deployment.
# Run this script to update to the latest/greatest and then check it in.
#

helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
kubectl config set-context --current --namespace=kube-system

helm template --name-template=falco stable/falco -f falco-values.yml > falco.yml

