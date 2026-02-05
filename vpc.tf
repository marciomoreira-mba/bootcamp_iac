module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "tracknow-prod"
  cidr = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1b"]

  # Públicas: ALB + Bastion (se quiser depois)
  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]

  # Privadas de app (EC2 Moodle)
  private_subnets = [
    "10.0.10.0/24",
    "10.0.11.0/24",
  ]

  # Vamos usar as mesmas private_subnets como "data" para simplificar;
  # se quiser separar mesmo, criamos outro módulo ou ajustamos cidrs.
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "tracknow-vpc"
    Environment = "prod"
  }
}
