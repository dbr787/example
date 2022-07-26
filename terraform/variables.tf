variable "aws_region" {
  description = "The AWS region to use."
  type        = string
  default     = "ap-southeast-2"
}

variable "project_id" {
  description = "An identifier for this project. Used for prefixing resource names and tagging resources."
  type        = string
  validation {
    condition     = length(var.project_id) <= 10
    error_message = "The project_id variable must 10 characters or less."
  }
}

variable "email" {
  description = "The users email address."
  type        = string
}

variable "vpc_cidr" {
  description = "The cidr block for the VPC being created."
  type        = string
}

variable "public_subnet_cidr" {
  description = "The cidr block for the public subnet being created."
  type        = string
}

variable "allowed_ip_cidrs" {
  description = "A list of ip addresses in cidr notation that are allowed access to resources."
  type        = list(any)
  default     = ["0.0.0.0/0"]
}

variable "buildkite_agents" {
  description = "A list of terraform objects or maps including the details or variables for each group of buildkite_agents to provision. See the buildkite-agents module for nested variable details."
  type        = list(any)
}

variable "buildkite_agent_token" {
  description = "The Buildkite agent token."
  type        = string
  sensitive   = true
}
