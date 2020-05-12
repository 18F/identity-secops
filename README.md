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
	* ~~Do CI for nessus/clamav to push to docker hub~~
	* Waiting for spinnaker work being done by Mike
* Make sure that security is baked in
	* IAM roles for access?
	* Istio for limiting outbound access and who can talk to what service?
	* Twistlock/Aqua/TenableCS for scanning containers after build?
	* ~~clamav~~
	* ~~falco~~
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
* Everybody has a different idea about how to do all this:  long lived branches
  vs trunk-based development, standalone vs hub/spoke.
	* Held a meeting, presented options, did exercise to surface consensus:
	  https://docs.google.com/document/d/1OtMXGJynZYuagcsIMDV9IzJjRyNmxVNVXz9Y78gcfOA/
* Spinnaker deploy seems to be broken
	* removed remnants, tried out [fluxcd](https://github.com/fluxcd/flux)

## Process

* `brew install kubectl aws-iam-authenticator fluxctl`
* make sure that your environment is set up to point at the AWS account that you want
  the cluster to live with `AWS_PROFILE` or AWS Vault.
* Deploy Kubernetes (see below)

### Deploying Kubernetes

* First time: `./setup.sh <clustername>` where `clustername` is something like `secops-dev` or `devops-test`
  You can also select a cluster type with `./setup.sh <clustername> <clustertype>`, which will select the
  `cluster-<clustertype>` directory for deploying stuff.  This lets you have a standalone or hub/spoke architecture.
	* Once the cluster is up, use `fluxctl --k8s-fwd-ns=flux-system identity` to get a readonly deploy key
	  to add to the git repo that the cluster is deployed from.  Once that is enabled, the code under the
	  clustertype dir will be deployed automatically as you check it into git.
	* Other repos can be deployed with flux as well.  Look at how `cluster/idp` is configured
	  to deploy https://github.com/timothy-spencer/idp-dev to the idp namespace.  You can also
	  look at https://github.com/timothy-spencer/idp-dev/workloads/idp-bluegreen for a very basic example of how to
	  do blue/green deploys with tests and so on.
* Deploy to already existing cluster:  `./deploy.sh <clustername>`



## Notes
k8s stuff:
* https://blog.gruntwork.io/comprehensive-guide-to-eks-worker-nodes-94e241092cbe#f8b9
* https://aws.amazon.com/blogs/opensource/getting-started-istio-eks/
* https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
* https://github.com/fluxcd/flux
* https://github.com/fluxcd/multi-tenancy
* https://github.com/fluxcd/multi-tenancy-team1
* https://docs.flagger.app/tutorials/kubernetes-blue-green
* https://aws.amazon.com/blogs/opensource/aws-service-operator-kubernetes-available/ (probably want to manage this externally, but interesting)
* https://monzo.com/blog/controlling-outbound-traffic-from-kubernetes

Nessus config stuff
* setup for Docker example:  https://github.com/SteveMcGrath/docker-nessus_scanner
* for cli configuration:  https://docs.tenable.com/nessus/Content/NessusCLI.htm
* simple chef recipe:  https://github.com/KennaSecurity/chef-nessus
