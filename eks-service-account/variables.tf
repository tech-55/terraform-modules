variable "aws_region" {
    description = "The AWS region to deploy resources in"
    type        = string
}

variable "namespace" {
    description = "The Kubernetes namespace where the service account is located"
    type        = string
}

variable "app_name" {
    description = "The name of the Kubernetes service account"
    type        = string
}

variable "policies" {
  type = list(object({
    allow_actions = list(string)
    allow_resources = list(string)
  }))
}

variable "bucket" {}
variable "eks_key" {}

variable "aws_account" {
  
}
