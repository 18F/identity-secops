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
* Logging and security should be built in
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
	* ~~Waiting for spinnaker work being done by Mike~~
	* ~~While waiting, try out flux!~~
* Make sure that security is baked in
	* ~~IAM roles for access?~~
	* Istio for limiting outbound access and who can talk to what service?  Maybe just Network Policies?
	* Twistlock/Aqua/TenableCS for scanning containers after build?
	* ~~clamav~~
	* ~~falco~~
* Figure out system for running k8s on local system too?
* super-stretch goal:  make helm chart for identity-idp and see if it works!
	* Managed to get container working with https://github.com/18F/identity-idp/pull/3759

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
* falco is now broken
	* They changed their helm repo and how software is delivered, the lkm disappeared that it needed.
	* Updated to latest helm repo, but their new system is broken:  https://github.com/falcosecurity/falco/issues/1255
* Spinnaker deploy seems to be broken
	* removed remnants, tried out [fluxcd with flagger](https://github.com/fluxcd/flux)
	* spinnaker was deployed in the `devops-test` cluster in `identity-sandbox`, but I cannot make it work in `secops-dev`.
	* spinnaker does not seem to be able to trigger off of new image builds.  Can see webhook happening in the logs, but no trigger?

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
* Update already existing cluster:  `./deploy.sh <clustername>`

### Deploying Notes

This was based heavily off of the [fluxcd multi-tenancy template](https://github.com/fluxcd/multi-tenancy).
Since we are not just deploying to one cluster, but to several, we have extended the setup to handle
multiple cluster types.

The underlying fluxcd stuff relies heavily on [kustomize](https://github.com/kubernetes-sigs/kustomize) to
pull together and customize the various manifests out there.  We have been trying to keep our configuration
rendered out into flat files rather than relying on remote repos or helm charts that may or may not be working.
Wherever possible, we are using some sort of `render_<thing>.sh` script to render the file(s) out for that
service.  In the cases where we have not, they are usually based on some prior art.  If you want to see what
is being generated for a particular thing, you should be able to say something like
`kustomize build cluster/` or `kustomize build base/elk` or whatever to see what is being applied.

#### Spinnaker
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
1. Run 

**Configuring Spinnaker**

It's pretty straightforward, the Spinnaker configuration is a declaritive manifest that's an [output of Terraform](spinnaker/outputs.tf). The entire configuration lives there, and the [Armory docs](https://docs.armory.io/operator_reference/operator-config/) are a great place to go and see an explict reference, where things live, and how to configure Spinnaker as a whole. Currently we're using the OSS Spinnaker distribution with no customization.

#### Spinnaker TODO

In no particular order.

* Use the [`aws_ip_ranges`](https://www.terraform.io/docs/providers/aws/d/ip_ranges.html) data source instead of [`aws_ranges.py`](spinnaker/aws-ranges.py).
* Use the [`random.random_password`](https://www.terraform.io/docs/providers/random/r/password.html) provider for passwords.
* Convert the [Kubernetes output locals](spinnaker/outputs.tf) to Kubernetes constructs.
* Convert the Kubernetes files to Terraform.
* Convert the [`bootstrap.sql`](spinnaker/bootstrap.sql) script to a [`null_resource` provider](https://stackoverflow.com/questions/49563301/terraform-local-exec-command-for-executing-mysql-script).
* Convert the [`bootstrap.sql`](spinnaker/bootstrap.sql) script to a Terraform local variable so the passwords can be interpolated; i.e. `locals { bootstrap_script = "CREATE USER 'clouddriver' IDENTIFIED BY \"${random_password.mysql_password}\";"}`.
* Create an input scheme so we don't have to rely on environment variables.
* VPC Peering so the Aurora instance doesn't need to be exposed on the internet.

Proposed `input.json` schema:

```json
{
	"eks_vpc_id": "vpc-abc1234",
	"base_domain": "identitysandbox.gov",
	"cluster_name": "devops-test",
	"region": "us-west-2",
	"oidc_endpoint": "oidc.eks.us-west-2.amazonaws.com/id/ABCD1234",
	"spinnaker_oauth_client_id": "spinnaker-dev",
	"spinnaker_oauth_client_secret": "pass",
	"spinnaker_oauth_access_token_uri": "https://localhost/oauth/token",
	"spinnaker_oauth_user_authorization_uri": "https://localhost/userinfo",
	"spinnaker_oauth_userinfo_uri": "https://localhost/oauth/authorize"
}
```

By having a set input schema, you could do something like this:

```hcl
data "external" "inputs" {
  program = ["cat", "${path.root}/input.json"]
}

resource "aws_route53_zone" "v2" {
  name = "v2.${data.external.inputs.result.base_domain}"
  // ...
}
```

The `input.json` could be dynamically generated and version controlled external to the Spinnaker deployment, making it a bit easier to deploy. Unfortunately, we can't easily work with the AWS STS and OAuth2 client information, so that will absolutely have to be passed in, there's no Terraform provider for OAuth2 implementations and the AWS STS information has to be preexisting in the environment.

## Upgrading EKS

To do this:
  * Update the version in `terraform/eks-cluster.tf`.
  * Get all the nodes with `kubectl get nodes --output=json | jq -r '.items[] | .metadata.name'`
  * Run `./deploy.sh <clustername>`.
  * Go into the console and click into the node group, click on upgrade.
  * Celebrate!  Everything should be running the latest/greatest stuff shortly.

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
