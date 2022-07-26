variable "project_id" {
  description = "An identifier for this project. Used for prefixing resource names and tagging resources."
  type        = string
  validation {
    condition     = length(var.project_id) <= 10
    error_message = "The project_id variable must 10 characters or less."
  }
}

variable "id" {
  description = "The unique id for the object. Used to identify the resources created in the iteration of the child module."
  type        = string
}

variable "platform" {
  description = "The platform of the operating system."
  type        = string
  validation {
    condition     = contains(["linux", "windows"], var.platform)
    error_message = "The platform variable must be either linux or windows."
  }
}

variable "instance_count" {
  description = "The number of instances to deploy matching the configuration provided in the object."
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "The ec2 instance type."
  type        = string
}

variable "ssh_user" {
  description = "The default user for the instance. This will be different for different operating systems."
  type        = string
}

variable "ami_owner" {
  description = "The owner filter to use in the buildkite_agent_ami data source to identify the ec2 ami to use."
  type        = string
}

variable "ami_name_filter" {
  description = "The name filter to use in the buildkite_agent_ami data source to identify the ec2 ami to use."
  type        = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "private_key_file" {
  type = string
}

variable "buildkite_agent_token" {
  description = "The Buildkite agent token."
  type        = string
  sensitive   = true
}
