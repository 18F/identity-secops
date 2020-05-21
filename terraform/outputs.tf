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
    - rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/FullAdministrator
      username: admin
      groups:
        - system:masters
    - rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/SOCAdministrator
      username: soc
      groups:
        - view
  # XXX this should work, but it's not?  Maybe because it's an assumed role?
  # mapUsers: |
  #   - userarn: arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/FullAdministrator/timothy.spencer
  #     username: admin
  #     groups:
  #       - system:masters
CONFIGMAPAWSAUTH

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

output "cluster_arn" {
  value = aws_eks_cluster.secops.arn
}

# output "idp_db_service" {
#   value = local.idp_redis_service
# }

