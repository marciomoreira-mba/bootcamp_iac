# Subnet group usando subnets privadas
resource "aws_elasticache_subnet_group" "redis" {
  name       = "tracknow-redis-subnets"
  subnet_ids = module.vpc.private_subnets
}

# SG de Redis (só EC2 Moodle acessa)
module "redis_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "tracknow-redis-sg"
  description = "Redis SG"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      description              = "Redis from app"
      source_security_group_id = module.app_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}

resource "aws_elasticache_replication_group" "redis_sessions" {
  replication_group_id = "tracknow-redis-sessions"
  description          = "Redis for sessions"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.small"

  # uma única instância, sem failover
  automatic_failover_enabled = false
  multi_az_enabled           = false

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [module.redis_sg.security_group_id]

  tags = {
    Name        = "tracknow-redis-sessions"
    Environment = "prod"
  }
}
