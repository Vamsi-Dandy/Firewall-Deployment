variable "key_name" {
  description = "Name of the key pair"
  type        = string
  default     = "aws-pa-keys"
}

variable "ssm_param_name" {
  description = "SSM parameter name for storing the private key"
  type        = string
  default     = "/ec2/private-key/PAFWDeployment"
}

variable "aws_region" {
  description = "AWS region to check/create the key pair"
  type        = string
}
