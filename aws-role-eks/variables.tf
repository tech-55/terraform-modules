variable "aws_region" {
    description = "The AWS region to deploy resources in"
    type        = string
}

variable "aws_account" {
  
}

variable "namespace" {
    description = "The Kubernetes namespace where the service account is located"
    type        = string
}

variable "app_name" {
    description = "The name of the Kubernetes service account"
    type        = string
}

variable "eks_oidc_provider_arn" {
    type = string
    description = "The ARN of the EKS OIDC provider"
}

variable "eks_oidc_issuer_host" {
    type = string
}

variable "policies" {
  type = list(object({
    allow_actions = list(string)
    allow_resources = list(string)
  }))
}