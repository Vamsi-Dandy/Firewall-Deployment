
resource "aws_security_group" "palo_alto_sg" {
  name        = "palo-alto-fw-sg"
  description = "Allow necessary traffic for Palo Alto"
  vpc_id       = data.aws_vpc.firewall_vpc.id

 ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allows all protocols
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16","164.55.0.0/16"] # RFC-1918 subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}