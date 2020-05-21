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
* You must have an existing, pre-deployed Route53 zone in the same AWS account you deploy both Kubernetes and Spinnaker to. The [`spinnaker/deploy-spinnaker.sh`](spinnaker/deploy-spinnaker.sh) script will be importing the Zone ID.
* You have an OAuth2 client with the `authorization_code` type for the authentication scheme.

**Creating an OAuth2 Client**

Once you've set up your local `uaa` client, you can create a client with this command:

```
uaa create-client spinnaker-dev \
	-s "<pass>" \
	--authorized_grant_types authorization_code \
	--display_name "Spinnaker Dev" \
	--scope "ops.read,ops.write,appdev.read,appdev.write,openid" \
	--redirect_uri "https://<gate-url>/login,http://localhost:8080"
```

For development work, you need to ensure you have `http://localhost:8080` in the redirect URL list so you can properly authenticate and test the client locally, otherwise it won't work.

**Steps:**
* Deploy Kubernetes.
* Enter the `spinnaker` directory.
* Run `./setup-spinnaker.sh <cluster_name>` to prep the terraform state.
* Export some variables. You can get the endpoints from the `https://<auth-server>/.well-known/openid-configuration` URL.
  * `export TF_VAR_spinnaker_oauth_client_id=""`
    * The OAuth2 client ID you want to use from the auth server.
  * `export TF_VAR_spinnaker_oauth_client_secret=""`
    * The OAuth2 client secret you want to use from the auth server.
  * `export TF_VAR_spinnaker_oauth_access_token_uri=""`
  * `export TF_VAR_spinnaker_oauth_userinfo_uri=""`
  * `export TF_VAR_spinnaker_oauth_user_authorization_uri=""`
* Once that's run, run `./deploy-spinnaker <cluster_name> <base_domain>`.
  * `<cluster_name>`: this should be the same the Kubernetes cluster that's deployed.
  * `<base_domain>`: The name of the Route53 zone you want to use. For example, `identitysandbox.gov`

**Bootstrapping RDS**

Unfortunately there's no easy way to bootstrap the Clouddriver database that Spinnaker needs without a lot of manual steps. This only needs to be done once, on first initialisation of RDS, and then these steps don't need to be taken again. Basically, we need to punch a hole in the firewall to create a couple things in the database, then we are going to tidy up what we did.

1. Make sure you are in the `spinnaker` directory.
1. In [spinnaker/db.tf](spinnaker/db.tf), make sure the `data.external.personal-ip` and `aws_security_group.allow-local-mysql` structs are uncommented.
1. Run the `./deploy-spinnaker.sh` script from the previous section again. This punches a hole in the firewall with your public IP.
1. Connect to the database via the CLI.
1. Execute the SQL in `bootstrap.sql`.


## Notes
k8s stuff:
* https://blog.gruntwork.io/comprehensive-guide-to-eks-worker-nodes-94e241092cbe#f8b9
* https://aws.amazon.com/blogs/opensource/getting-started-istio-eks/
* https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html

Nessus config stuff
* setup for Docker example:  https://github.com/SteveMcGrath/docker-nessus_scanner
* for cli configuration:  https://docs.tenable.com/nessus/Content/NessusCLI.htm
* simple chef recipe:  https://github.com/KennaSecurity/chef-nessus
