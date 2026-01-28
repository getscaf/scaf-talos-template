# Create new hosted zone only if no existing zone is specified
resource "aws_route53_zone" "route_zone" {
  count = var.existing_hosted_zone == "" ? 1 : 0
  name  = var.domain_name
  tags  = local.common_tags
}

# Reference existing hosted zone if specified
data "aws_route53_zone" "existing_zone" {
  count = var.existing_hosted_zone != "" ? 1 : 0
  name  = var.existing_hosted_zone
}

# Local value to determine which zone to use
locals {
  zone_id = var.existing_hosted_zone == "" ? aws_route53_zone.route_zone[0].zone_id : data.aws_route53_zone.existing_zone[0].zone_id
}

resource "aws_route53_record" "k8s" {
  zone_id = local.zone_id
  name    = var.cluster_domain_name
  type    = "CNAME"
  records = [module.elb_k8s_elb.elb_dns_name]
  ttl     = 600
}
