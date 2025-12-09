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

variable "bucket" {}
variable "eks_key" {}
