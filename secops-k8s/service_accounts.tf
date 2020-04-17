resource "kubernetes_role" "deploy" {
  metadata {
    name = "deploy"
    namespace = "default"
  }

  rule {
    api_groups     = [""]
    resources      = ["deployments", "services", "persistentvolumeclaims"]
    verbs          = ["create", "update"]
  }
}
