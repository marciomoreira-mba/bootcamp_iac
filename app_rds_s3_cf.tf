#####################
# SG da App (EC2 ) e do RDS
#####################

module "app_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "tracknow-app-sg"
  description = "Moodle EC2 SG"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "HTTP do ALB"
      source_security_group_id = aws_security_group.alb_sg.id
    }
  ]

  egress_rules = ["all-all"]
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "tracknow-rds-sg"
  description = "RDS SG"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "Postgres da app"
      source_security_group_id = module.app_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}

#####################
# EC2 
#####################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

module "ec2_moodle" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name                   = "tracknow-moodle"
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.app_sg.security_group_id]

  # você pode criar depois um script user_data_moodle.sh e ligar aqui
  user_data = null

  tags = {
    Role        = "moodle"
    Environment = "prod"
  }
}

#####################
# RDS Postgres
#####################

resource "aws_kms_key" "rds" {
  description             = "KMS key for TrackNow RDS"
  deletion_window_in_days = 7
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "tracknow-db"

  engine               = "postgres"
  engine_version       = "17.6"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = "db.t3.medium"

  storage_type          = "gp3"
  allocated_storage     = 100
  max_allocated_storage = 200

  db_name  = "tracknow"
  username = "tracknow_app"
  password = var.db_master_password
  port     = 5432

  multi_az            = false
  publicly_accessible = false

  # chave: subnet group explícito nas mesmas subnets da VPC do módulo
  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  vpc_security_group_ids = [module.rds_sg.security_group_id]

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  backup_retention_period = 7
  maintenance_window      = "Sun:03:00-Sun:04:00"
  backup_window           = "04:00-05:00"

  deletion_protection = false

  tags = {
    Name        = "tracknow-rds"
    Environment = "prod"
  }
}
