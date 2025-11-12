
terraform {
  required_providers {
    kubectl = { source = "gavinbunney/kubectl", version = "~> 1.14" }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubectl" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

data "aws_eks_cluster_auth" "this" { name = var.eks_cluster_name }

data "aws_iam_policy_document" "sa_policy_doc" {
  statement {
    effect  = "Allow"
    actions = var.allow_actions
    resources = var.allow_resources
  }
}

resource "aws_iam_policy" "service_account_policy" {
  name        = "${var.namespace}-${var.service_account_name}-policy"
  description = "Scoped DynamoDB access for accountService via IRSA"
  policy      = data.aws_iam_policy_document.sa_policy_doc.json
}

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "OIDCTrust"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "service_account_role" {
  name               = "${var.namespace}-${var.service_account_name}-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  description        = "IRSA role for accountService pods to access DynamoDB"
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.service_account_role.name
  policy_arn = aws_iam_policy.service_account_policy.arn
}


resource "kubectl_manifest" "service_account" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${var.service_account_name}
  namespace: ${var.namespace}
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.service_account_role.arn}
YAML

depends_on = [aws_iam_role.service_account_role]
}