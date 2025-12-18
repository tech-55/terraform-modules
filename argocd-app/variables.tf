variable "aws_region" {}
variable "aws_account" {}

variable "bucket" {}
variable "argocd_key" {}
variable "eks_key" {}

variable "app_name" {}
variable "namespace" {}
variable "github_repo_url" {}

variable "argocd_sources" {
  type = object({
    helmTargetRevision = optional(string, "0.1.21")
    helmValues     = string
    branch         = string
  })
}