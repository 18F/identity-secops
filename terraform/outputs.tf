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

#   idp_db_service = <<DBSERVICE
# apiVersion: v1
# kind: Service
# metadata: 
#   labels: 
#     name: idp-postgres
#   name: idp-postgres
# spec: 
#   type: ExternalName
#   externalName: ${aws_db_instance.idp.address}
#   ports: 
#     - port: 5432
#       protocol: TCP
#       targetPort: ${aws_db_instance.idp.port}
# DBSERVICE

#   idp_redis_service = <<REDISSERVICE
# XXX
# REDISSERVICE

}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}

output "kubeconfig" {
  value = local.kubeconfig
}

output "cluster_arn" {
  value = aws_eks_cluster.secops.arn
}

# output "idp_db_service" {
#   value = local.idp_redis_service
# }

