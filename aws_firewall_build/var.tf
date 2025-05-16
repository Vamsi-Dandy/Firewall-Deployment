variable "region" {
  description = "AWS region"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for Palo Alto firewall"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m5.xlarge"
}

variable "subnet_id" {
  description = "List of Subnet IDs where the firewalls will be deployed"
  type        = list(string)
}

variable "gwlb_target_group_arn" {
  description = "ARN of the existing GWLB target group"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "firewall_count" {
  description = "Number of firewall instances to deploy"
  type        = number
}

variable "aws_account" {
  description = "Account number where the firewalls are being built"
  type        = string
}

variable "iam_role" {
  description = "IAM role to attach to the instance"
  type        = string
  default     = "service-execution-iam-role"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "aws-pa-keys"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for Palo Alto bootstrap"
  type        = string
}


variable "panorama_ip" {
  description = "IP address of Panorama"
  type        = string
}

variable "template_stack" {
  description = "Template stack name to be used in init-cfg.txt"
  type        = string
}

variable "device_group" {
  description = "Device group name to be used in init-cfg.txt"
  type        = string
}

variable "ssm_region" {
  description = "Region where SSM parameters are stored"
  type        = string
  default     = "us-east-1"
}

variable "ssm_vm_auth_key_param" {
  description = "SSM parameter name for vm-auth-key"
  type        = string
  default     = " /fwdeployment/vm-auth-key"
}

variable "ssm_registration_pin_id_param" {
  description = "SSM parameter name for registration PIN ID"
  type        = string
  default     = "/fwdeployment/registration-pin-id"
}

variable "ssm_registration_pin_value_param" {
  description = "SSM parameter name for registration PIN value"
  type        = string
  default     = "/fwdeployment/registration-pin-value"
}

variable "ssm-region" {
  description = "AWS region where all SSM parameter values are stored"
  type        = string
  default     = "us-east-1"
}

variable "panos_version" {
  description = "Major PAN-OS version to filter for (e.g., 11.1.4)"
  type        = string
  default     = "11.1.4"
}