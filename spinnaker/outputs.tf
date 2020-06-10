# we're reading in the manually generated kubeconfig file for spinnaker
data "local_file" "kubeconfig" {
  filename = "${path.root}/kubeconfig.yaml"
}

locals {
  # see the docs on what to do with this.
  spinnaker_service = <<SPINNAKEREOF
apiVersion: spinnaker.io/v1alpha2
kind: SpinnakerService
metadata:
  name: spinnaker
  namespace: identity-system
spec:
  spinnakerConfig:
    files:
      kubeconfig-dev: |
${data.local_file.kubeconfig.content}
    config:
      version: 1.20.3
      features:
        artifactsRewrite: true
      providers:
        kubernetes:
          enabled: true
          primaryAccount: dev
          accounts:
          - name: dev
            providerVersion: V2
            serviceAccount: true
        dockerRegistry:
          enabled: true
          primaryAccount: logindotgov-demo
          accounts:
          - name: logindotgov-demo
            address: https://index.docker.io
            email: "identity-devops@login.gov"
            username: logindotgovrobot
            password: "" # todo (mxplusb): variablise this.
            repositories:
            - logindotgov/pretend-app
      artifacts:
        github:
          enabled: true
          accounts:
          - name: 18f
            username: identity-servers
            password: "" # todo (mxplusb): variablise this.
      deploymentEnvironment:
        customSizing:
          spin-clouddriver:
            replicas: 1
            requests:
              cpu: 100m
              memory: 512Mi
            limits:
              cpu: 250m
              memory: 4Gi
          spin-deck:
            replicas: 1
            requests:
              cpu: 100m
              memory: 512Mi
            limits:
              cpu: 250m
              memory: 2Gi
          spin-gate:
            replicas: 1
            requests:
              cpu: 100m
              memory: 512Mi
            limits:
              cpu: 250m
              memory: 2Gi
          spin-echo:
            replicas: 1
            requests:
              cpu: 100m
              memory: 512Mi
            limits:
              cpu: 250m
              memory: 2Gi
          spin-front50:
            replicas: 1
            requests:
              cpu: 100m
              memory: 512Mi
            limits:
              cpu: 250m
              memory: 2Gi
          spin-rosco:
            replicas: 1
            requests:
              cpu: 100m
              memory: 512Mi
            limits:
              cpu: 250m
              memory: 2Gi
          spin-orca:
            replicas: 1
            requests:
              cpu: 100m
              memory: 512Mi
            limits:
              cpu: 250m
              memory: 2Gi
      persistentStorage:
        persistentStoreType: s3
        s3:
          bucket: "${aws_s3_bucket.spinnaker-s3.bucket}"
          accessKeyId: "${aws_iam_access_key.spinnaker-s3.id}"
          secretAccessKey: "${aws_iam_access_key.spinnaker-s3.secret}"
          rootFolder: front50
      security:
        apiSecurity:
          overrideBaseUrl: "https://gate.${var.cluster_name}.v2.${var.base_domain}"
        uiSecurity:
          overrideBaseUrl: "https://ci.${var.cluster_name}.v2.${var.base_domain}"
        authn:
          oauth2:
            enabled: true
            client:
              clientId: "${var.spinnaker_oauth_client_id}"
              clientSecret: "${var.spinnaker_oauth_client_secret}"
              accessTokenUri: "${var.spinnaker_oauth_access_token_uri}"
              userAuthorizationUri: "${var.spinnaker_oauth_user_authorization_uri}"
              scope: "openid"
            provider: OTHER
            resource:
              userInfoUri: "${var.spinnaker_oauth_userinfo_uri}"
            userInfoMapping:
              email: email
              firstName: given_name
              lastName: family_name
              username: email
    profiles:
      clouddriver:
        sql:
          enabled: true
          taskRepository:
            enabled: true
          cache:
            enabled: true
            readBatchSize: 500
            writeBatchSize: 300
          scheduler:
            enabled: true
          connectionPools:
            default:
              # additional connection pool parameters are available here,
              # for more detail and to view defaults, see:
              # https://github.com/spinnaker/kork/blob/master/kork-sql/src/main/kotlin/com/netflix/spinnaker/kork/sql/config/ConnectionPoolProperties.kt
              default: true
              jdbcUrl: jdbc:mysql://${aws_rds_cluster.spinnaker.endpoint}:3306/clouddriver?user=clouddriver&password=clouddriver123
            tasks:
              user: clouddriver
              jdbcUrl: jdbc:mysql://${aws_rds_cluster.spinnaker.endpoint}:3306/clouddriver?user=clouddriver&password=clouddriver123
          migration:
            user: clouddriver
            jdbcUrl: jdbc:mysql://${aws_rds_cluster.spinnaker.endpoint}:3306/clouddriver?user=clouddriver&password=clouddriver123
        redis:
          enabled: false
          cache:
            enabled: false
          scheduler:
            enabled: false
          taskRepository:
            enabled: false
      deck:
        settings-local.js: |
          window.spinnakerSettings.feature.kustomizeEnabled = true;
          window.spinnakerSettings.feature.artifactsRewrite = true;
      echo: {}   
      fiat: {}   
      front50: {}  
      gate: 
        server:
          tomcat:
            protocolHeader: X-Forwarded-Proto
            remoteIpHeader: X-Forwarded-For
            internalProxies: .*
            httpsServerPort: X-Forwarded-Port
      igor: {}   
      kayenta: {}
      orca:
        sql:
          enabled: true
          connectionPool:
            jdbcUrl: jdbc:mysql://${aws_rds_cluster.spinnaker.endpoint}:3306/orca?user=orca&password=orca123
            connectionTimeout: 5000
            maxLifetime: 30000
          migration:
            jdbcUrl: jdbc:mysql://${aws_rds_cluster.spinnaker.endpoint}:3306/orca?user=orca&password=orca123
        executionRepository:
          sql:
            enabled: true
          redis:
            enabled: false
        monitor:
          activeExecutions:
            redis: false
      rosco: {}  
    service-settings:
      clouddriver:
        kubernetes:
          serviceAccountName: spinnaker-service-account
      deck: {}
      echo: {}
      fiat: {}
      front50:
        sql:
          enabled: true
          connectionPools:
            default:
              default: true
              jdbcUrl: jdbc:mysql://${aws_rds_cluster.spinnaker.endpoint}:3306/front50?user=front50&password=front50123   
          migration:
            jdbcUrl: jdbc:mysql://${aws_rds_cluster.spinnaker.endpoint}:3306/front50?user=front50&password=front50123 
      gate: {}
      igor: {}
      kayenta: {}
      orca: {}
      rosco: {}
    files: {}
  expose: {}
SPINNAKEREOF

spinnaker_ingress = <<SPININGRESS
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: spin-deck
  namespace: identity-system
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: "${aws_acm_certificate.ci.arn}"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443, "HTTP": 80}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    external-dns.alpha.kubernetes.io/hostname: "ci.${var.cluster_name}.v2.${var.base_domain}"
spec:
  rules:
  - host: "ci.${var.cluster_name}.v2.${var.base_domain}"
    http:
      paths:
      - backend:
          serviceName: ssl-redirect
          servicePort: use-annotation
        path: /*
      - backend:
          serviceName: spin-deck
          servicePort: 9000
        path: /*
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: spin-gate
  namespace: identity-system
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: "${aws_acm_certificate.gate.arn}"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443, "HTTP": 80}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    external-dns.alpha.kubernetes.io/hostname: "gate.${var.cluster_name}.v2.${var.base_domain}"
spec:
  rules:
  - host: "gate.${var.cluster_name}.v2.${var.base_domain}"
    http:
      paths:
      - backend:
          serviceName: ssl-redirect
          servicePort: use-annotation
        path: /*
      - backend:
          serviceName: spin-gate
          servicePort: 8084
        path: /*
SPININGRESS

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

alb_controller = <<ALBEOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: alb-ingress-controller
  name: alb-ingress-controller
  namespace: identity-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: alb-ingress-controller
  template:
    metadata:
      labels:
        app.kubernetes.io/name: alb-ingress-controller
    spec:
      containers:
        - name: alb-ingress-controller
          resources:
            limits:
              memory: "512Mi"
          args:
            - --ingress-class=alb
            - --cluster-name=devops-test
            - --aws-api-debug
          env:
            - name: AWS_ACCESS_KEY_ID
              value: "${aws_iam_access_key.spinnaker-transit.id}"
            - name: AWS_SECRET_ACCESS_KEY
              value: "${aws_iam_access_key.spinnaker-transit.secret}"
          image: docker.io/amazon/aws-alb-ingress-controller:v1.1.6
      serviceAccountName: alb-ingress-controller
ALBEOF
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

output "alb-controller" {
  value = local.alb_controller
}

output "spinnaker-ingress" {
  value = local.spinnaker_ingress
}

output "spinnaker-db-host" {
  value = aws_rds_cluster.spinnaker.endpoint
}
