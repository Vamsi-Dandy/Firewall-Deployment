# Data source to fetch the VPC ID using a specific tag
data "aws_vpc" "firewall_vpc" {
  # Filter to find the VPC with the tag key and value
  filter {
    name   = "tag:operation"
    values = ["firewall-vpc"]
  }
}

# Output the VPC ID
output "firewall_vpc_id" {
  value = data.aws_vpc.firewall_vpc.id
}

output "palo_alto_ami_id" {
  value = data.aws_ami.palo_alto_vmseries_byol.id
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


data "aws_ssm_parameter" "panorama_api_key" {
  name = "/panwvmseries/devpanorama"
  with_decryption = true
}

data "aws_ami" "palo_alto_vmseries_byol" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["6njl1pau431dv1qxipg63mvah"]
  }

  filter {
    name   = "name"
    values = ["*PA-VM-AWS-${var.  panos_version}-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  # owners = ["679593333241"] # Palo Alto Networks AWS account ID
}