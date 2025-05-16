resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.this.public_key_openssh

  tags = {
    Name = var.key_name
  }
}

resource "aws_ssm_parameter" "private_key" {
  name              = var.ssm_param_name
  type              = "SecureString"
  value_wo          = tls_private_key.this.private_key_pem
  value_wo_version  = 1

  tags = {
    Name = "${var.key_name}-private-key"
  }
}
