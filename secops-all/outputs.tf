#
# Outputs
#

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.secops-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${aws_iam_role.codebuild.arn}
      username: deploy
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.secops.endpoint}
    certificate-authority-data: ${aws_eks_cluster.secops.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster_name}"
KUBECONFIG

  # see the docs on what to do with this.
  spinnaker_service = <<SPINNAKEREOF
apiVersion: spinnaker.armory.io/v1alpha2
kind: SpinnakerService
metadata:
  name: spinnaker
  namespace: identity-system
spec:
  spinnakerConfig:
    config:
      version: 2.15.1
      persistentStorage:
        persistentStoreType: s3
        s3:
          bucket: "${aws_s3_bucket.spinnaker.bucket}"
          rootFolder: front50
    profiles:
      clouddriver: {}
      deck:
        settings-local.js: |
          window.spinnakerSettings.feature.kustomizeEnabled = true;
          window.spinnakerSettings.feature.artifactsRewrite = true;
      echo: {}   
      fiat: {}   
      front50: {}
      gate: {}   
      igor: {}   
      kayenta: {}
      orca: {}   
      rosco: {}  
    service-settings:
      clouddriver: {}
      deck: {}
      echo: {}
      fiat: {}
      front50: {}
      gate: {}
      igor: {}
      kayenta: {}
      orca: {}
      rosco: {}
    files: {}
  expose:
    type: service
    service:
      type: LoadBalancer
      annotations: {}
      overrides:
        deck:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "${aws_acm_certificate.ci.arn}"
            service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https
        gate:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "${aws_acm_certificate.gate.arn}"
            service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https
        gate-x509:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "${aws_acm_certificate.gate.arn}"
          publicPort: 443
SPINNAKEREOF
}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}

output "kubeconfig" {
  value = local.kubeconfig
}

output "spinnaker-service" {
  value = local.spinnaker_service
}
