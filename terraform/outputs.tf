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

  idp_db_configmap = <<DBCONFIGMAP
apiVersion: v1
kind: ConfigMap
metadata:
  name: idp-postgres
  namespace: idp
  labels:
    name: idp-postgres
data:
  hostname: "${aws_db_instance.idp.address}"
  port: "${aws_db_instance.idp.port}"
DBCONFIGMAP

  idp_redis_service = <<REDISSERVICE
apiVersion: v1
kind: Service
metadata: 
  labels: 
    name: idp-redis
  name: idp-redis
spec: 
  type: ExternalName
  externalName: ${aws_elasticache_replication_group.idp.primary_endpoint_address}
  ports: 
    - port: 6379
      protocol: TCP
      targetPort: 6379
REDISSERVICE

}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}

output "cluster_arn" {
  value = aws_eks_cluster.secops.arn
}

output "idp_db_configmap" {
  value = local.idp_db_configmap
}

output "idp_redis_service" {
  value = local.idp_redis_service
}
