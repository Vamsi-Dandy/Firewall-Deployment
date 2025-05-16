output "fw_names" {
  description = "Names of all firewall instances"
  value       = [for instance in aws_instance.palo_alto_fw : instance.tags["Name"]]
}


output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "region" {
  value = var.region
}