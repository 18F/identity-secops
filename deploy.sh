#!/bin/sh
#
# This script does the initial setup for the secops environment.
# You should only run this once to get it going, then just use terraform apply
# after that.
# 
set -e

if [ -z "$1" ]; then
     echo "usage:  $0 <cluster_name>"
     echo "example: ./deploy.sh secops-dev"
     exit 1
else
     export TF_VAR_cluster_name="$1"
fi

checkbinary() {
     if which "$1" >/dev/null ; then
          return 0
     else
          echo no "$1" found: exiting
          exit 1
     fi
}

REQUIREDBINARIES="
     terraform
     aws
     kubectl
     jq
"
for i in ${REQUIREDBINARIES} ; do
     checkbinary "$i"
done


# some config
ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
REGION="us-west-2"
BUCKET="login-dot-gov-secops.${ACCOUNT}-${REGION}"
SCRIPT_BASE=$(dirname "$0")
RUN_BASE=$(pwd)


if [ -z "$GITHUB_TOKEN" ] ; then
  echo "GITHUB_TOKEN needs to be set so that the deploy webhooks can be set up"
  exit 1
fi

# clean up tfstate files so that we get them from the backend
find . -name terraform.tfstate -print0 | xargs -0 rm

# set it up with the s3 backend
cd "$SCRIPT_BASE/secops-all"
terraform init -backend-config="bucket=$BUCKET" \
      -backend-config="key=tf-state/$TF_VAR_cluster_name" \
      -backend-config="dynamodb_table=secops_terraform_locks" \
      -backend-config="region=$REGION" \
      -upgrade
terraform apply

# This updates the kubeconfig so that the nodes can talk with the masters
# and also maps IAM roles to users.
aws eks update-kubeconfig --name "$TF_VAR_cluster_name"
rm -f /tmp/configmap.yml
terraform output config_map_aws_auth > /tmp/configmap.yml
kubectl apply -f /tmp/configmap.yml
rm -f /tmp/configmap.yml

# this turns on the EBS persistent volume stuff
# XXX do we want to set this up with helm instead or tie it to a release/version?
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

cd "$RUN_BASE/secops-k8s"
terraform init -backend-config="bucket=$BUCKET" \
      -backend-config="key=tf-state/${TF_VAR_cluster_name}_k8s" \
      -backend-config="dynamodb_table=secops_terraform_locks" \
      -backend-config="region=$REGION" \
      -upgrade
terraform apply

# install all of the infrastructure k8s stuff
kubectl apply -f "$SCRIPT_BASE/secops-k8s/k8s/*.yaml"
