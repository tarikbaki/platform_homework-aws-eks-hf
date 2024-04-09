module "iam" {
  source = "../modules/iam"
  hosted_zone_arn = aws_route53_zone.homework.arn
}

