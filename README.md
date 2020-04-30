# Security Infrastructure

The security team needs a place to segregate login.gov's secops
tooling capabilities and prepare to integrate SOCaaS. Additionally,
to start automation to support IR and assessment work

## Initial Requirements
* Need to build Nessus scanner with code
* System for getting Nessus going needs to be automated
	* Changes to code should cause tests and deployment to happen (CI/CD)
	  automatically.
	* If Nessus dies, it should be restarted/rebuilt.
* Secrets and maybe artifacts used for build/deploy should be persisted somewhere
* System should be roughly generalizable to other purposes


## Plan
* Get EKS going with terraform (like EKS because you can run k8s locally too)
	* ~~terraform shared state should be set up~~
	* ~~have logging going to... ELK?~~
	* ~~secrets/config persist somewhere (vault?  AWS Secrets manager?)~~
	* ~~build requirements persist somewhere (s3?)~~
	* ~~persistent volumes should be EBS~~
* get CI/CD going to deploy a helm chart.  Maybe ES?  Use codebuild?
	* ~~CircleCI?  Codebuild?  Spinnaker?  Concourse:  start with Codebuild~~
	* ~~put stuff into ECR~~
	* ~~get codepipeline to kick off builds~~
	* retooling to do builds with circleci into docker hub, will be relying on spinnaker work being done by Mike
* Make sure that security is baked in
	* IAM roles for access?
	* Istio?
	* Twistlock/Aqua/TenableCS?
	* ~~clamav~~
	* falco
* Figure out system for running k8s on local system too?
* super-stretch goal:  make helm chart for identity-idp and see if it works!
	* Mike and others are doing this

## Problems encountered so far
* EKS/Fargate only works in us-east-* regions, we are in us-west-2.
	* Solution:  Try doing with regular node groups, sigh.
	* Thoughts (@mxplusb): Fargate doesn't give us enough control, methinks.
* eksctl is great, but doesn't provide fine-grained control over environment
	* Solution:  Use terraform
* nessus needs to use a persistent volume
	* first try:  tarball /opt/nessus and unpack if empty
* nessus needs to upgrade it's code, but pv doesn't do that
	* bundle nessus deb into container and install every time we run?  Seems terrible.
	* nessus automatically upgrades itself, so nevermind
* clamav scan was terrible, not finding stuff in /tmp
	* retooled to scan everything, but this takes a long time
	* probably going to rejigger to do a scan on deploy, then inotify for changes

## Process

* `brew install kubectl`
* `brew install aws-iam-authenticator`
* make sure that your environment is set up to point at the AWS account that you want
  the cluster to live with `AWS_PROFILE` or AWS Vault.
* Deploy Kubernetes
* Optionally, deploy Spinnaker.

### Deploying Kubernetes

* First time: `./setup.sh <clustername>` where `clustername` is something like `secops-dev` or `devops-test`
* Deploys to already existing cluster:  `./deploy.sh <clustername>`

### Deploying Spinnaker

**Requirements:**
* Kubernetes must be deployed.
* You must have an existing, pre-deployed Route53 zone in the same AWS account you deploy both Kubernetes and Spinnaker to. The `./deploy-spinnaker.sh` script will be importing the Zone ID.

**Steps:**
* Deploy Kubernetes.
* Run `./setup-spinnaker.sh <cluster_name>` to prep the terraform state.
* Once that's run, run `./deploy-spinnaker <cluster_name> <base_domain>`.
  * `<cluster_name>`: this should be the same the Kubernetes cluster that's deployed.
  * `<base_domain>`: The name of the Route53 zone you want to use. For example, `identitysandbox.gov`


## Notes
k8s stuff:
* https://blog.gruntwork.io/comprehensive-guide-to-eks-worker-nodes-94e241092cbe#f8b9
* https://aws.amazon.com/blogs/opensource/getting-started-istio-eks/
* https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html

Nessus config stuff
* setup for Docker example:  https://github.com/SteveMcGrath/docker-nessus_scanner
* for cli configuration:  https://docs.tenable.com/nessus/Content/NessusCLI.htm
* simple chef recipe:  https://github.com/KennaSecurity/chef-nessus
