data "aws_caller_identity" "default"{}
#### Get the aws vpc, subnet and rds objects
data "aws_vpc" "default" {
  id = var.aws_db_vpc_id
}
data "aws_subnet" "default" {
  for_each = toset(var.aws_db_subnet_ids)
  id = each.key
}
data "aws_db_instance" "default" {
  db_instance_identifier = var.aws_rds_mysql_instance_name
}

# Define the nlb for mysql rds instance 
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow MySQL traffic"
  vpc_id      = data.aws_vpc.default.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }
}

# NLB Creation
resource "aws_lb" "default" {
  name               = "${var.aws_rds_mysql_instance_name}-prvlink"
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.db_sg.id]
  subnets            = [for subnet in data.aws_subnet.default: subnet.id]
  enable_cross_zone_load_balancing = true

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "default" {
  name        = "${var.aws_rds_mysql_instance_name}-prvlink"
  port        = 3306
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
}

data "dns_a_record_set" "proxy" {
  host = aws_db_proxy.default.endpoint
}

resource "aws_lb_target_group_attachment" "default" {
  for_each = toset(data.dns_a_record_set.proxy.addrs)

  target_group_arn = aws_lb_target_group.default.arn
  target_id        = each.value
  port             = 3306
  depends_on = [ aws_db_proxy.default ]
}

# NLB Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.default.arn
  port              = 3306
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

## Make sure to run these commands 

# Enable DNS Support and DNS Hostnames using local-exec provisioner
resource "null_resource" "enable_dns_support" {
  provisioner "local-exec" {
    command = "aws ec2 modify-vpc-attribute --vpc-id ${var.aws_db_vpc_id} --enable-dns-support --region ${var.aws_region}"
  }

  triggers = {
    vpc_id = var.aws_db_vpc_id
  }
}

resource "null_resource" "enable_dns_hostnames" {
  provisioner "local-exec" {
    command = "aws ec2 modify-vpc-attribute --vpc-id ${var.aws_db_vpc_id} --enable-dns-hostnames --region ${var.aws_region}"
  }

  triggers = {
    vpc_id = var.aws_db_vpc_id
  }
}

# VPC Endpoint Service (PrivateLink)
resource "aws_vpc_endpoint_service" "nlb_endpoint_service" {
  network_load_balancer_arns = [aws_lb.default.arn]
  acceptance_required        = false  # Control whether you need to manually accept endpoint connections
  # allowed_principals = ["*"]  # Optionally restrict who can create the endpoint by specifying ARNs
  allowed_principals = [confluent_gateway.default.aws_egress_private_link_gateway[0].principal_arn]
}