locals {
  firewall_names = [for i in range(var.firewall_count) : "pa-${var.environment}-${var.region}-${i + 1}"]
  bootstrap_prefixes = [for name in local.firewall_names : "bootstrap/${name}"]
}

resource "null_resource" "generate_bootstrap" {
  count = var.firewall_count

  triggers = {
    region                  = var.region
    account_id              = data.aws_caller_identity.current.account_id
    panorama_ip             = var.panorama_ip
    hostname                = local.firewall_names[count.index]
    panorama_api_key        = data.aws_ssm_parameter.panorama_api_key.value
    template_stack          = var.template_stack
    device_group            = var.device_group
    ssm_authcode_param      = var.ssm_vm_auth_key_param
    ssm_pin_id_param        = var.ssm_registration_pin_id_param
    ssm_pin_value_param     = var.ssm_registration_pin_value_param
    ssm_region              = var.ssm-region
    bootstrap_prefix        = local.bootstrap_prefixes[count.index]
  }

  provisioner "local-exec" {
    command = <<EOT
      set -e
      python3 ${path.module}/bootstrap_generator.py \
        --region ${var.region} \
        --account-id ${data.aws_caller_identity.current.account_id} \
        --panorama-ip ${var.panorama_ip} \
        --hostname "${local.firewall_names[count.index]}" \
        --panorama-api-key ${data.aws_ssm_parameter.panorama_api_key.value} \
        --template-stack ${var.template_stack} \
        --device-group ${var.device_group} \
        --ssm-authcode-param ${var.ssm_vm_auth_key_param} \
        --ssm-pin-id-param ${var.ssm_registration_pin_id_param} \
        --ssm-pin-value-param ${var.ssm_registration_pin_value_param} \
        --ssm-region ${var.ssm-region} \
        --bootstrap-prefix "${local.bootstrap_prefixes[count.index]}"
    EOT
  }
}

resource "null_resource" "log_firewall_metadata" {
  count = var.firewall_count
  
  triggers = {
    region                  = var.region
    account_id              = data.aws_caller_identity.current.account_id
    panorama_ip             = var.panorama_ip
    hostname                = "pa-${var.environment}-${var.region}-${count.index + 1}"
    panorama_api_key        = data.aws_ssm_parameter.panorama_api_key.value
    template_stack          = var.template_stack
    device_group            = var.device_group
    ssm_authcode_param      = var.ssm_vm_auth_key_param
    ssm_pin_id_param        = var.ssm_registration_pin_id_param
    ssm_pin_value_param     = var.ssm_registration_pin_value_param
    ssm_region              = var.ssm-region
  }

  provisioner "local-exec" {
    command = <<EOT
      set -e
      python3 ${path.module}/log_firewall_metadata.py \
        --region ${var.region} \
        --hostname "pa-${var.environment}-${var.region}-${count.index + 1}" \
        --bucket ${var.s3_bucket_name} \
        --panorama-ip ${var.panorama_ip} \
        --panorama-api-key ${data.aws_ssm_parameter.panorama_api_key.value} \
        --bootstrap-prefix "bootstrap/pa-${var.environment}-${var.region}-${count.index + 1}"
    EOT
  }

  depends_on = [aws_instance.palo_alto_fw]
}


resource "aws_network_interface" "mgmt_eni" {
  count         = var.firewall_count
  subnet_id     = var.subnet_id[count.index]
  security_groups   = [aws_security_group.palo_alto_sg.id]
  description   = "mgmt-eni"
}

resource "aws_network_interface" "data_eni" {
  count         = var.firewall_count
  subnet_id     = var.subnet_id[count.index]
  security_groups   = [aws_security_group.palo_alto_sg.id]
  description   = "data-eni"
}

resource "aws_instance" "palo_alto_fw" {
  count                  = var.firewall_count
  # ami                    = var.ami_id
  ami                    = data.aws_ami.palo_alto_vmseries_byol.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = var.iam_role
  disable_api_termination = false

  network_interface {
    network_interface_id = aws_network_interface.mgmt_eni[count.index].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.data_eni[count.index].id
    device_index         = 1
  }

  tags = {
    "Name"                   = local.firewall_names[count.index]
    "fds:Patching:Ownership"  = "Appliance"
    "fds:Schedule"            = "fds:standard:no-schedule"
  }

  user_data = <<EOF
vmseries-bootstrap-aws-s3bucket=${var.s3_bucket_name}/${local.bootstrap_prefixes[count.index]}
EOF

  depends_on = [null_resource.generate_bootstrap]
}

resource "aws_lb_target_group_attachment" "fw_attachment" {
  count              = var.firewall_count
  target_group_arn   = var.gwlb_target_group_arn
  target_id          = aws_instance.palo_alto_fw[count.index].id
  port               = 6081  # GWLB uses GENEVE (UDP 6081)
  depends_on         = [aws_instance.palo_alto_fw]
}

output "firewall_ip" {
  value = [for instance in aws_instance.palo_alto_fw : instance.public_ip]
}

output "firewall_instance_id" {
  value = [for instance in aws_instance.palo_alto_fw : instance.id]
}
