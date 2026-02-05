#resource "aws_route53_record" "app" {
#  zone_id = var.hosted_zone_id
#  name    = "app.tracknow.com.br"
#  type    = "A"

#  alias {
#    name                   = module.cloudfront.cloudfront_distribution_domain_name
#    zone_id                = module.cloudfront.cloudfront_distribution_hosted_zone_id
#    evaluate_target_health = false
#  }
#}
