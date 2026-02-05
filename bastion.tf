module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "tracknow-bastion-sg"
  description = "Bastion SG"
  vpc_id      = module.vpc.vpc_id

  # ajuste o cidr da sua origem (por ex. seu IP residencial)
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]

  egress_rules = ["all-all"]
}

module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name                   = "tracknow-bastion"
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.bastion_sg.security_group_id]

  associate_public_ip_address = true

  tags = {
    Role        = "bastion"
    Environment = "prod"
  }
}
