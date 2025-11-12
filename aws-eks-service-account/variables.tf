variable "aws_region" {
    description = "The AWS region to deploy resources in"
    type        = string
}

variable "namespace" {
    description = "The Kubernetes namespace where the service account is located"
    type        = string
}

variable "service_account_name" {
    description = "The name of the Kubernetes service account"
    type        = string
}

variable "allow_actions" {
    description = "List of allowed actions for the IAM policy"
    type        = list(string)
}

variable "allow_resources" {
    type       = list(string)
    description = "List of allowed resources for the IAM policy"
}

variable "eks_cluster_name" {
    description = "The name of the EKS cluster"
    type        = string
}

variable "eks_cluster_endpoint" {
    type = string
    description = "The endpoint of the EKS cluster"
}

variable "eks_cluster_certificate_authority_data" {
    type        = string
    description = "The base64 encoded certificate authority data for the EKS cluster"
    sensitive = true
}

variable "eks_oidc_provider_arn" {
    type = string
    description = "The ARN of the EKS OIDC provider"
}

variable "eks_oidc_issuer_host" {
    type = string
}