locals {
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
          bucket: "${aws_s3_bucket.spinnaker-s3.bucket}"
          accessKeyId: "${aws_iam_access_key.spinnaker-s3.user}"
          secretAccessKey: "${aws_iam_access_key.spinnaker-s3.secret}"
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

output "spinnaker-service" {
  value = local.spinnaker_service
}
