resource "kubernetes_storage_class" "ebs" {
  storage_provisioner = "ebs.csi.aws.com"
  metadata {
    name = "ebs"
    # Would be nice if this worked.
    # annotations = {
    #   is-default-class = true
    # }
  }
  volume_binding_mode = "WaitForFirstConsumer"
}
