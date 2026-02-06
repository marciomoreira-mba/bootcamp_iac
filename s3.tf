module "s3_static_assets" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "tracknow-prod-static"

  # ACL explícita + configuração de ownership compatível com ACL
  acl                       = "private"
  control_object_ownership  = true
  object_ownership          = "BucketOwnerPreferred"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  tags = {
    Name        = "tracknow-static-assets"
    Environment = "prod"
  }
}
