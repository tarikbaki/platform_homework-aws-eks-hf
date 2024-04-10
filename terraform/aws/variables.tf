################################################################################
variable "environment" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "assume_role_name" {
  type = string
}

variable "assume_role_session_name" {
  type = string
}

variable "cidr" {
  type = string
  validation {
    condition = try(cidrnetmask(var.cidr), null) == "255.255.0.0"
    error_message = "cidr must be /16 long"
  }
}

variable "vpc_azs" {
  type = list(string)
}

variable "readonly_role_arn" {
  type = string
}

variable "administrator_role_arn" {
  type = string
}

################################################################################

variable "hosted_zone" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "backendlb_name" {
  type = string
  default = ""
}

variable "create" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  default     = 30
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
}


