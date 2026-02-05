variable "db_master_password" {
  description = "Senha do usuário master do RDS"
  type        = string
  sensitive   = true
}

#variable "hosted_zone_id" {
#  description = "ID da hosted zone Route53 (para app.tracknow.com.br)"
#  type        = string
#}
