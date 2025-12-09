

provider "aws" {
  region = var.aws_region
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

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  host                   = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file = false
}

module "create_aws_role_eks" {
  source = "../aws-role-eks"
    
  aws_region               = var.aws_region
  eks_oidc_provider_arn    = data.terraform_remote_state.eks.outputs.eks_oidc_provider_arn
  eks_oidc_issuer_host     = data.terraform_remote_state.eks.outputs.eks_oidc_issuer_host
  namespace                = var.namespace
  service_account_name     = var.service_account_name
  allow_actions            = var.allow_actions
  allow_resources          = var.allow_resources
}


resource "kubectl_manifest" "tls_secret" {
yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${var.service_account_name}
  namespace: ${var.namespace}
  annotations:
    eks.amazonaws.com/role-arn: ${module.create_aws_role_eks.role_arn}
YAML
  
  depends_on = [ module.create_aws_role_eks ]
}
