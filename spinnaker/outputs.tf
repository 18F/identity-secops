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
          accessKeyId: "${aws_iam_access_key.spinnaker-s3.id}"
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

dns_service_account = <<SAEOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  namespace: identity-system
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.spinnaker-transit.arn}
SAEOF

external_dns_deployment = <<DNSEOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: identity-system
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: registry.opensource.zalan.do/teapot/external-dns:latest
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=${var.cluster_name}.v2.${var.base_domain}
        - --provider=aws
        - --aws-prefer-cname
        - --policy=upsert-only
        - --aws-zone-type=public
        - --registry=noop
        - --log-level=debug
      securityContext:
        fsGroup: 65534
DNSEOF
}

output "spinnaker-service" {
  value = local.spinnaker_service
}

output "spinnaker-external-dns-service-account" {
  value = local.dns_service_account
}

output "spinnaker-external-dns-deploy" {
  value = local.external_dns_deployment
}
