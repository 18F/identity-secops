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

  spinnaker_service = <<SPINNAKEREOF
apiVersion: spinnaker.armory.io/v1alpha2
kind: SpinnakerService
metadata:
  name: spinnaker
spec:
  # spec.spinnakerConfig - This section is how to specify configuration spinnaker
  spinnakerConfig:
    # spec.spinnakerConfig.config - This section contains the contents of a deployment found in a halconfig .deploymentConfigurations[0]
    config:
      version: 2.15.1   # the version of Spinnaker to be deployed
      persistentStorage:
        persistentStoreType: s3
        s3:
          bucket: "${aws_s3_bucket.spinnaker.bucket}"
          rootFolder: front50

    # spec.spinnakerConfig.profiles - This section contains the YAML of each service's profile
    profiles:
      clouddriver: {} # is the contents of ~/.hal/default/profiles/clouddriver.yml
      # deck has a special key "settings-local.js" for the contents of settings-local.js
      deck:
        # settings-local.js - contents of ~/.hal/default/profiles/settings-local.js
        # Use the | YAML symbol to indicate a block-style multiline string
        settings-local.js: |
          window.spinnakerSettings.feature.kustomizeEnabled = true;
          window.spinnakerSettings.feature.artifactsRewrite = true;
      echo: {}    # is the contents of ~/.hal/default/profiles/echo.yml
      fiat: {}    # is the contents of ~/.hal/default/profiles/fiat.yml
      front50: {} # is the contents of ~/.hal/default/profiles/front50.yml
      gate: {}    # is the contents of ~/.hal/default/profiles/gate.yml
      igor: {}    # is the contents of ~/.hal/default/profiles/igor.yml
      kayenta: {} # is the contents of ~/.hal/default/profiles/kayenta.yml
      orca: {}    # is the contents of ~/.hal/default/profiles/orca.yml
      rosco: {}   # is the contents of ~/.hal/default/profiles/rosco.yml

    # spec.spinnakerConfig.service-settings - This section contains the YAML of the service's service-setting
    # see https://www.spinnaker.io/reference/halyard/custom/#tweakable-service-settings for available settings
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

    # spec.spinnakerConfig.files - This section allows you to include any other raw string files not handle above.
    # The KEY is the filepath and filename of where it should be placed
    #   - Files here will be placed into ~/.hal/default/ on halyard
    #   - __ is used in place of / for the path separator
    # The VALUE is the contents of the file.
    #   - Use the | YAML symbol to indicate a block-style multiline string
    #   - We currently only support string files
    #   - NOTE: Kubernetes has a manifest size limitation of 1MB
    files: {}
  #      profiles__rosco__packer__example-packer-config.json: |
  #        {
  #          "packerSetting": "someValue"
  #        }
  #      profiles__rosco__packer__my_custom_script.sh: |
  #        #!/bin/bash -e
  #        echo "hello world!"


  # spec.expose - This section defines how Spinnaker should be publicly exposed
  expose:
    type: service  # Kubernetes LoadBalancer type (service/ingress), note: only "service" is supported for now
    service:
      type: LoadBalancer

      # annotations to be set on Kubernetes LoadBalancer type
      # they will only apply to spin-gate, spin-gate-x509, or spin-deck
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
        # uncomment the line below to provide an AWS SSL certificate to terminate SSL at the LoadBalancer
        #service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-west-2:9999999:certificate/abc-123-abc

      # provide an override to the exposing KubernetesService
      overrides: {}
      # Provided below is the example config for the Gate-X509 configuration
#        deck:
#          annotations:
#            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-west-2:9999999:certificate/abc-123-abc
#            service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
#        gate:
#          annotations:
#            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:us-west-2:9999999:certificate/abc-123-abc
#            service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https  # X509 requires https from LoadBalancer -> Gate
#       gate-x509:
#         annotations:
#           service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
#           service.beta.kubernetes.io/aws-load-balancer-ssl-cert: null
#         publicPort: 443
SPINNAKEREOF
}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}

output "kubeconfig" {
  value = local.kubeconfig
}
