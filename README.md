# EKS Fargate Test

Goals:
* get EKS/Fargate going with terraform
	* have IAM role support for users
	* have logging going to... ELK?  CW?
	* security/access managed somehow (istio?)
	* ssm access to pods?
* get CI/CD going to deploy a helm chart.  Maybe ES?  Use codebuild?
	* CircleCI?  Codebuild?  Spinnaker?
* make helm chart for identity-idp


## process

* `terraform apply`
* `brew install kubectl`
* `brew install aws-iam-authenticator`
* `aws eks --region us-east-2 update-kubeconfig --name ekstest`
* `kubectl patch deployment coredns -n kube-system --type json \
-p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'`
* `kubectl rollout restart -n kube-system deployment coredns`

## Notes
https://blog.gruntwork.io/comprehensive-guide-to-eks-worker-nodes-94e241092cbe#f8b9
https://aws.amazon.com/blogs/opensource/getting-started-istio-eks/