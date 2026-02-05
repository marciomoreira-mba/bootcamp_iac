module "s3_static_assets" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "tracknow-prod-static"

  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = { enabled = true }

  tags = {
    Name        = "tracknow-static-assets"
    Environment = "prod"
  }
}
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.0"

  aliases = ["app.tracknow.com.br"]

  origin = {
    s3_static = {
      domain_name = module.s3_static_assets.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_static_oai"
      }
    }
  }

  origin_access_identities = {
    s3_static_oai = "Access identity for tracknow-prod-static"
  }

  default_cache_behavior = {
    target_origin_id       = "s3_static"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.tracknow.arn

  tags = {
    Name        = "tracknow-cloudfront"
    Environment = "prod"
  }
}

