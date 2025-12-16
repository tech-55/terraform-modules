provider "aws" {
  region = var.aws_region
}

data "aws_iam_policy_document" "sa_policy_doc" {
  statement {
    effect  = "Allow"
    actions = var.allow_actions
    resources = var.allow_resources
  }
}

locals {
  aws_sandbox_account_id = "864899843511"  //sandbox account id
  aws_pci_account_id = "535424203419"  //pci account id
  aws_production_account_id = "112233445566"  //production account id

  suffix_app_name = var.aws_account == local.aws_sandbox_account_id ? "-snb" : var.aws_account == local.aws_pci_account_id ? "-prd" : var.aws_account == local.aws_production_account_id ? "-pci-prd" : "unknown"
  app_name = "${var.app_name}${local.suffix_app_name}"

}

resource "aws_iam_policy" "service_account_policy" {
  name        = "${var.namespace}-${local.app_name}-policy"
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
      values   = ["system:serviceaccount:${var.namespace}:${local.app_name}"]
    }
  }
}

resource "aws_iam_role" "service_account_role" {
  name               = "${var.namespace}-${local.app_name}-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  description        = "IRSA role for accountService pods to access DynamoDB"
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.service_account_role.name
  policy_arn = aws_iam_policy.service_account_policy.arn
}