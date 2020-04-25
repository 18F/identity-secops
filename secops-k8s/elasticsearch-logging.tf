
data "helm_repository" "elastic" {
  name = "stable"
  url  = "https://Helm.elastic.co"
}

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch-logging"
  namespace  = "kube-system"
  repository = data.helm_repository.elastic.metadata[0].url
  chart      = "elasticsearch"
}

resource "helm_release" "kibana" {
  name       = "kibana"
  namespace  = "kube-system"
  repository = data.helm_repository.elastic.metadata[0].url
  chart      = "kibana"
}

