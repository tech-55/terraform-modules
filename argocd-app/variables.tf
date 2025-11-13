
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

variable "argocd_sources" {
  type = list(object({
    repoURL        = string
    targetRevision = optional(string)
    chart          = optional(string)
    helm = optional(object({
      valueFiles  = optional(list(string))
      values      = optional(string)
      parameters  = optional(list(object({
        name        = string
        value       = string
        forceString = optional(bool)
      })))
    }))
  }))
}

variable "argocd_syncPolicy" {
  type = object({
    automated = optional(object({
      prune    = optional(bool)
      selfHeal = optional(bool)
    }))
  })
}