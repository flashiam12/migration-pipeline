##### 
# mysql -h eap-test-with-nlb-shiv.cndsjke6xo5r.us-west-2.rds.amazonaws.com -P 3306 -u admin -p

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
resource "aws_lb" "network_load_balancer" {
  name               = "${var.aws_rds_mysql_instance_name}-prvlink"
  internal           = true
  load_balancer_type = "network"
  security_groups    = []
  subnets            = var.aws_db_subnet_ids

  enable_deletion_protection = false
}

# NLB Target Group
resource "aws_lb_target_group" "mysql_target_group" {
  name     = "${var.aws_rds_mysql_instance_name}-prvlink"
  port     = 3306
  protocol = "TCP"
  vpc_id   = data.aws_vpc.default.id
}

# NLB Target Group attachment 
resource "aws_lb_target_group_attachment" "mysql_target_group_attachment" {
  target_group_arn = aws_lb_target_group.mysql_target_group.arn
  target_id        = data.aws_db_instance.default.endpoint  # You may need to fetch this dynamically
  port             = 3306  # The port your RDS instance is listening on
}

# NLB Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.network_load_balancer.arn
  port              = 3306
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mysql_target_group.arn
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
  network_load_balancer_arns = [aws_lb.network_load_balancer.arn]
  acceptance_required        = false  # Control whether you need to manually accept endpoint connections

  allowed_principals = ["*"]  # Optionally restrict who can create the endpoint by specifying ARNs
#   allowed_principals = ["arn:aws:iam::730335223811:role/${data.confluent_environment.default.id}-role"]
}


