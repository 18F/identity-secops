resource "kubernetes_role" "deploy" {
  metadata {
    name = "deploy"
    namespace = "default"
  }

  rule {
    api_groups     = [""]
    resources      = ["deployments", "services", "persistentvolumeclaims"]
    verbs          = ["create", "update", "get"]
  }
  rule {
    api_groups     = ["apps"]
    resources      = ["deployments"]
    verbs          = ["create", "update", "get", "patch"]
  }
  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    verbs          = ["list", "create", "update"]
  }
}

resource "kubernetes_role_binding" "deploy" {
  metadata {
    name      = "deploy"
    namespace = "default"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "deploy"
  }
  subject {
    kind      = "User"
    name      = "deploy"
    api_group = "rbac.authorization.k8s.io"
  }
}
