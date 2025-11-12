
variable "aws_region" {
    description = "The AWS region to deploy resources in"
    type        = string
}

variable "bucket" {}
variable "argocd_key" {}
variable "eks_key" {}

variable "app_name" {}
variable "namespace" {}
variable "github_repo_url" {}
variable "argocd_source" {
  description = "Flexible Argo CD source definition"
  type        = map(any)
}

variable "argocd_syncPolicy" {
   type        = map(any)
}