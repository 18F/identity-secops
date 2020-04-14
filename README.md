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
	* terraform shared state should be set up
	* have logging going to... ELK?  CW?
	* secrets/config persist somewhere (vault?  AWS Secrets manager?)
	* build requirements persist somewhere (s3?)  Should discuss.
* get CI/CD going to deploy a helm chart.  Maybe ES?  Use codebuild?
	* CircleCI?  Codebuild?  Spinnaker?  Concourse:  start with Codebuild
	* put stuff into ECR
* Make sure that security is baked in
	* IAM roles for access?
	* Istio?
	* Twistlock/Aqua/TenableCS?
* super-stretch goal:  make helm chart for identity-idp and see if it works!

## Problems encountered so far
* EKS/Fargate only works in us-east-* regions, we are in us-west-2.
	* Solution:  Try doing with regular node groups, sigh.
* eksctl is great, but doesn't provide fine-grained control over environment
	* Solution:  Use terraform

## process

* `brew install kubectl`
* `brew install aws-iam-authenticator`
* First time: `./setup.sh <clustername>` where `clustername` is something like `secops-dev`
* Deploys to already existing cluster:  `./deploy.sh <clustername>`


## Notes
k8s stuff:
* https://blog.gruntwork.io/comprehensive-guide-to-eks-worker-nodes-94e241092cbe#f8b9
* https://aws.amazon.com/blogs/opensource/getting-started-istio-eks/
* https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html

Nessus config stuff
* setup for Docker example:  https://github.com/SteveMcGrath/docker-nessus_scanner
* for cli configuration:  https://docs.tenable.com/nessus/Content/NessusCLI.htm
* simple chef recipe:  https://github.com/KennaSecurity/chef-nessus
