#!/bin/sh
#
# This script does the initial setup for the secops environment.
# You should only run this once to get it going, then just use terraform apply
# after that.
# 
set -e

if [ -z "$1" ]; then
     echo "usage:   $0 <cluster_name>"
     echo "example: ./setup.sh secops-dev"
     exit 1
else
     export TF_VAR_cluster_name="$1"
fi

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
REGION="us-west-2"
BUCKET="login-dot-gov-secops.${ACCOUNT}-${REGION}"
SCRIPT_BASE=$(dirname "$0")
RUN_BASE=$(pwd)

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

# create the state bucket if it does not exist
if aws s3 ls s3://"$BUCKET" --region "$REGION" >/dev/null 2>&1 ; then
	echo terraform state bucket "$BUCKET" exists
else
	aws s3 mb s3://"$BUCKET" --region "$REGION"
fi

# create the dynamo db for the state bucket locking
if aws dynamodb describe-table --table-name secops_terraform_locks --region "$REGION" >/dev/null 2>&1 ; then
	echo dynamodb state lock is set up
else
	aws dynamodb create-table \
          --region "$REGION" \
          --table-name secops_terraform_locks \
          --attribute-definitions AttributeName=LockID,AttributeType=S \
          --key-schema AttributeName=LockID,KeyType=HASH \
          --sse-specification Enabled=true \
          --provisioned-throughput ReadCapacityUnits=2,WriteCapacityUnits=1

	aws dynamodb wait table-exists --table-name secops_terraform_locks --region "$REGION"
fi

# set it up with the s3 backend
cd "$RUN_BASE/$SCRIPT_BASE/terraform"
terraform init -backend-config="bucket=$BUCKET" \
      -backend-config="key=tf-state/$TF_VAR_cluster_name" \
      -backend-config="dynamodb_table=secops_terraform_locks" \
      -backend-config="region=$REGION"

# import the resources we just made
terraform import aws_s3_bucket.tf-state "$BUCKET"
terraform import aws_dynamodb_table.tf-lock-table secops_terraform_locks

# Here we go!  This is where the magic happens.  :-)
"$RUN_BASE/$SCRIPT_BASE/deploy.sh" "$1"

