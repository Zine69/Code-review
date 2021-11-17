terraform {
  backend "s3" {
    bucket = "test-argocd-eks"
    key    = "terraform/state"
    region = "us-east-1"
  }
}

module "cert_manager" {
  source = "github.com/sculley/terraform-kubernetes-cert-manager"

}

