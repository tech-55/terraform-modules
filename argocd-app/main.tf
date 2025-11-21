terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
  }
}

locals {
  aws_sandbox_account_id = "864899843511"  //sandbox account id
  automate_sync = var.aws_account == local.aws_sandbox_account_id ? true : false
  helm_chart_url = "https://tech-55.github.io/tech55-infra-apps-helm-charts"
  helm_chart_name = "app"
  argocd_sources_map = { for source in var.argocd_sources : source.branch => source }
  argocd_app_name = "${var.namespace}-${ var.app_name }-app"
  argocd_nasmespace = "argocd"
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
    name      = "repo-github-${ var.app_name }-secret"
    namespace = local.argocd_nasmespace
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
    githubAppPrivateKey  = base64decode(data.terraform_remote_state.argocd.outputs.argocd_github_app_rsa_private_key_base64)
  }
}

resource "kubernetes_manifest" "argocd_app" {

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = local.argocd_app_name
      namespace = local.argocd_nasmespace
    }
    spec = {
      project = local.argocd_app_name
      ources = [
        {
          repoURL        = local.helm_chart_url
          targetRevision = var.argocd_sources.helmTargetRevision,
          chart          = local.helm_chart_name
          helm = {
            valueFiles = [
              "$values/${var.argocd_sources.helmValues}"
            ]
          }
        },
        {
          repoURL        = var.github_repo_url
          targetRevision = var.argocd_sources.branch,
          ref = "values"
        }
      ]

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.namespace
      }

      syncPolicy = {
        automated = {
          prune = local.automate_sync
          selfHeal = local.automate_sync
        }
      }
    }
  }
}


resource "kubernetes_manifest" "argocd_image_updater" {
  for_each = local.argocd_sources_map

  manifest = {
    apiVersion = "argocd-image-updater.argoproj.io/v1alpha1"
    kind       = "ImageUpdater"
    metadata = {
      name      = "${var.namespace}-${ var.app_name }-${ each.value.branch }-image-updater"
      namespace = local.argocd_nasmespace
    }
    spec = {
      namespace = local.argocd_nasmespace

      writeBackConfig = {
        method = "git"
        gitConfig = {
          repository = var.github_repo_url
          branch = each.value.branch
          writeBackTarget = "helmvalues:.${each.value.helmValues}"
        }
      }
      
      commonUpdateSettings = {
        updateStrategy = "semver"       # or "latest" / "digest" etc. 
        forceUpdate =  true
      }
      
      applicationRefs = [{
          namePattern  =  local.argocd_app_name                # This matches metadata.name of the Argo CD Application
          images = [{
            alias =  "${lower(local.argocd_app_name)}-${lower(each.value.branch)}"   # An alias to identify this image within the application
            imageName = "${var.aws_account}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.app_name}"  # ECR image name
              # How to map this image into your Helm values
              manifestTargets = {
                helm = {
                  name = "image.repository"   # .Values.image.repository
                  tag = "image.tag"           # .Values.image.tag
                }
              }

        }]
      }]
    }
  }
}