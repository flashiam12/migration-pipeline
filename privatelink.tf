resource "aws_security_group" "privatelink" {
  # Ensure that SG is unique, so that this module can be used multiple times within a single VPC
  name = "ccloud-privatelink_${confluent_private_link_attachment.default.display_name}_${data.aws_vpc.default.id}"
  description = "Confluent Cloud Private Link minimal security group for ${confluent_private_link_attachment.default.display_name} in ${data.aws_vpc.default.id}"
  vpc_id = data.aws_vpc.default.id

  ingress {
    # only necessary if redirect support from http/https is desired
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  ingress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_vpc_endpoint" "privatelink" {
  vpc_id = data.aws_vpc.default.id
  service_name = confluent_private_link_attachment.default.aws.0.vpc_endpoint_service_name
  vpc_endpoint_type = "Interface"
  auto_accept = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]

  subnet_ids = [for zone, subnet_id in zipmap(var.aws_db_subnet_zones, var.aws_db_subnet_ids): subnet_id]
  private_dns_enabled = false
}

resource "confluent_private_link_attachment_connection" "default" {
  display_name = "${confluent_private_link_attachment.default.display_name}-${data.aws_vpc.default.id}"
  environment {
    id = confluent_environment.default.id
  }
  aws {
    vpc_endpoint_id = aws_vpc_endpoint.privatelink.id
  }
  private_link_attachment {
    id = confluent_private_link_attachment.default.id
  }
}

resource "aws_route53_zone" "private" {
  name = confluent_private_link_attachment.default.dns_domain

  vpc {
    vpc_id = data.aws_vpc.default.id
  }
}

resource "aws_route53_record" "default" {
  zone_id = aws_route53_zone.private.id
  name    = "*"
  type    = "CNAME"
  ttl     = 300
  records        = [aws_vpc_endpoint.privatelink.dns_entry.0.dns_name]
}

data "aws_availability_zones" "available" {}

locals {
  endpoint_dns_entry = [for obj in aws_vpc_endpoint.privatelink.dns_entry : obj.dns_name]
  subnet_zone_mapping = {
    for idx, az in zipmap(data.aws_availability_zones.available.names, data.aws_availability_zones.available.zone_ids) : 
    az => idx
  }
  endpoint_dns_map = zipmap(local.endpoint_dns_entry, local.endpoint_dns_entry)
  result = {for zone, region in local.subnet_zone_mapping : 
    zone => length([
    for idx, str in local.endpoint_dns_entry :
    idx if can(regex(region, str))
  ]) > 0 ? [for idx, str in local.endpoint_dns_entry : local.endpoint_dns_entry[idx] if can(regex(region, str))][0] : null
  }
  dns_entry_map = {
    for key, value in local.result : key => value if value != null
  }
}

resource "aws_route53_record" "private_dns_entries" {
  for_each = toset(var.aws_db_subnet_zones)

  zone_id = aws_route53_zone.private.id
  name    = "*.${each.value}.${var.aws_region}.aws.private.confluent.cloud"
  type    = "CNAME"
  ttl     = 300
  records = [local.dns_entry_map[each.value]]
}