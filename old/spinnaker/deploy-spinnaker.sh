#!/bin/sh
#
# This script does the initial setup for the secops environment.
# You should only run this once to get it going, then just use terraform apply
# after that.
# 
set -e

if [ "$#" -ne 2 ]; then
     echo "usage:  $0 <cluster_name> <base_domain>"
     echo "example: $0 devops-dev identitysandbox.gov"
     exit 1
else
     export TF_VAR_cluster_name="$1"
     export TF_VAR_base_domain="$2"
fi

checkbinary() {
     if which "$1" >/dev/null ; then
          return 0
     else
          echo no "$1" found: exiting
          exit 1
     fi
}

okay_to_fail() {
     if "$@"  >/dev/null 2>&1 ; then
	     echo "Command failed, but that's okay: $@"
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


# some aws config
ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
REGION="us-west-2"
BUCKET="login-dot-gov-devops.${ACCOUNT}-${REGION}"
export TF_VAR_oidc_endpoint=$(aws eks describe-cluster \
     --name $TF_VAR_cluster_name \
     --query "cluster.identity.oidc.issuer" \
     --output text | sed -e "s/^https:\/\///")

if [ -z "$GITHUB_TOKEN" ] ; then
  echo "GITHUB_TOKEN needs to be set so that the deploy webhooks can be set up"
  exit 1
fi

# clean up tfstate files so that we get them from the backend
find . -name terraform.tfstate -print0 | xargs -0 rm

# set it up with the s3 backend, push into the directory.
terraform init -backend-config="bucket=$BUCKET" \
      -backend-config="key=tf-state/$TF_VAR_cluster_name" \
      -backend-config="dynamodb_table=devops_terraform_locks" \
      -backend-config="region=$REGION" \
      -upgrade

# grab the hosted zone and import it.
BASE_DOMAIN=$(echo "${TF_VAR_base_domain}.")
HOSTED_ZONE=$(aws route53 list-hosted-zones | jq -r --arg base_domain $BASE_DOMAIN '.HostedZones[] | select(.Name == $base_domain) | .Id | split("/")[2]')

okay_to_fail terraform import aws_route53_zone.dns $HOSTED_ZONE

terraform apply

# apply base spinnaker
kubectl apply -f "." --wait

# update deploy spinnaker
rm -f spinnaker.yml
terraform output spinnaker-service > spinnaker.yml
kubectl apply -f spinnaker.yml
rm -f spinnaker.yml
