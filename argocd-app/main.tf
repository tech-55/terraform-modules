terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "argocd" {
  backend = "s3"

  config = {
    bucket         = var.bucket
    key            = var.argocd_key
    region         = var.aws_region
  }
}


data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket         = var.bucket
    key            = var.eks_key
    region         = var.aws_region
  }
}

data "aws_eks_cluster_auth" "this" { name = data.terraform_remote_state.eks.outputs.eks_cluster_name }

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "kubernetes_secret_v1" "argocd_github_repo" {
  metadata {
    name      = "repo-github-${ var.app_name }"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"
  data = {
    type                 = "git"
    project              = "default"
    url                  = var.github_repo_url
    githubAppID          = data.terraform_remote_state.argocd.outputs.argocd_github_app_id
    githubAppInstallationID = data.terraform_remote_state.argocd.outputs.argocd_github_app_installation_id
    githubAppPrivateKey  = data.terraform_remote_state.argocd.outputs.argocd_github_app_rsa_private_keys
  }
}

resource "kubernetes_manifest" "app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "${var.namespace}-${ var.app_name }"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = var.argocd_source

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.namespace
      }

      syncPolicy = var.argocd_syncPolicy
    }
  }
}
