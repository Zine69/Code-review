resource "time_sleep" "wait_2_minutes" {
  depends_on = [aws_eks_node_group.primary]

  create_duration = "2m"
}


resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress-controller"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  depends_on = [time_sleep.wait_2_minutes]
}

