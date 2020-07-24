#!/bin/sh

if [ -z "$1" ] ; then
	echo "usage:  $0 <clustername>"
	exit 1
fi

if kubectl config get-contexts | awk '{print $2}' | grep "$1" >/dev/null ; then
	echo "using $1 for the clustername"
else
	echo "could not find $1 as a cluster in our kubeconfig"
	exit 1
fi

helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm repo update

#helm install incubator/aws-alb-ingress-controller --set autoDiscoverAwsRegion=true --set autoDiscoverAwsVpcID=true --set clusterName=MyClusterName
#helm template incubator/aws-alb-ingress-controller --set autoDiscoverAwsRegion=true --set autoDiscoverAwsVpcID=true --set clusterName="$1" > "alb-ingress-$1.yaml"
helm template "$1" incubator/aws-alb-ingress-controller --set clusterName="$1" --set autoDiscoverAwsRegion=true --set autoDiscoverAwsVpcID=true --namespace kube-system > "alb-ingress-$1.yaml"

curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.8/docs/examples/iam-policy.json

