variable "account_id" {
  description = "The AWS account ID"
  type        = string
  default     = "{{ copier__aws_account_id }}"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "{{ copier__aws_region }}"
}

variable "app_name" {
  description = "Application Name"
  type        = string
  default     = "{{ copier__project_dash }}"
}

variable "environment" {
  description = "Environment Name"
  type        = string
  default     = "sandbox"
}

variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "{{ copier__project_dash }}-sandbox"
}

variable "domain_name" {
  type    = string
  default = "{{ copier__domain_name }}"
}

variable "cluster_domain_name" {
  type    = string
  default = "k8s.{{ copier__domain_name }}"
}

variable "kubernetes_version" {

  description = "Kubernetes version to use for the cluster, if not set the k8s version shipped with the Talos SDK will be used"
  type        = string
  default     = null
}

variable "talos_version" {
  description = "Talos version to use for the cluster AMI"
  type        = string
  default     = "{{ copier__talos_version }}"
}

variable "control_plane" {
  description = "Info for control plane that will be created"
  type = object({
    instances = map(object({
      instance_type = optional(string, "t3a.medium")
      ami_id        = optional(string, null)
      disk_size     = optional(number, 100)
      subnet_index  = number
      tags          = optional(map(string), {})
    }))
    config_patch_files = optional(list(string), [])
  })

  validation {
    condition = alltrue([
      for k, v in var.control_plane.instances :
      v.ami_id != null ? (length(v.ami_id) > 4 && substr(v.ami_id, 0, 4) == "ami-") : true
    ])
    error_message = "All ami_id values must be valid AMI ids, starting with \"ami-\"."
  }

  default = {
    instances = {
      "0" = { subnet_index = 0 }
      "1" = { subnet_index = 1 }
      "2" = { subnet_index = 2 }
    }
  }
}

variable "cluster_vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "config_patch_files" {
  description = "Path to talos config path files that applies to all nodes"
  type        = list(string)
  default     = []
}

variable "admin_allowed_ips" {
  description = "A list of CIDR blocks that are allowed to access the kubernetes api"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "existing_hosted_zone" {
  description = "Name of existing hosted zone to use instead of creating a new one"
  type        = string
  default     = "{{ copier__existing_hosted_zone }}"
}
