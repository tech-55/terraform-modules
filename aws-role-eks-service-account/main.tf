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