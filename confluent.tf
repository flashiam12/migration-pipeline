resource "confluent_service_account" "default" {
  display_name = "${var.cc_env}-ops-admin"
  description  = "Service Account for orders app"
}

resource "confluent_environment" "default" {
  display_name = var.cc_env
  stream_governance {
    package = "ESSENTIALS"
  }
  lifecycle {
    prevent_destroy = false
  }
}

data "confluent_schema_registry_cluster" "default" {
  environment {
    id = confluent_environment.default.id
  }
  depends_on = [ confluent_kafka_cluster.default ]
}

resource "confluent_role_binding" "all-subjects-default-rb" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.default.resource_name}/subject=*"
}

resource "confluent_private_link_attachment" "default" {
  cloud = "AWS"
  region = "us-west-2"
  display_name = "eap-test-platt"
  environment {
    id = confluent_environment.default.id
  }
}

resource "confluent_kafka_cluster" "default" {
  display_name = "${var.cc_kafka_cluster_name}"
  availability = "MULTI_ZONE"
  cloud        = "AWS"
  region       = var.aws_region
  enterprise {}
  environment {
    id = confluent_environment.default.id
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_api_key" "default" {
  display_name = "${var.cc_kafka_cluster_name}-admin"
  description  = "Kafka API Key that is owned by admin"
  owner {
    id          = confluent_service_account.default.id
    api_version = confluent_service_account.default.api_version
    kind        = confluent_service_account.default.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.default.id
    api_version = confluent_kafka_cluster.default.api_version
    kind        = confluent_kafka_cluster.default.kind

    environment {
      id = confluent_environment.default.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_role_binding" "cluster-admin" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.default.rbac_crn
}

resource "confluent_role_binding" "topic-write" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.default.rbac_crn}/kafka=${confluent_kafka_cluster.default.id}/topic=*"
}

resource "confluent_role_binding" "topic-read" {
  principal   = "User:${confluent_service_account.default.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.default.rbac_crn}/kafka=${confluent_kafka_cluster.default.id}/topic=*"
}

resource "confluent_gateway" "default" {
  display_name = "${var.aws_db_vpc_id}-rds-${var.aws_rds_mysql_instance_name}-gateway"
  environment {
    id = confluent_environment.default.id
  }
  aws_egress_private_link_gateway {
    region = var.aws_region
  }
}

resource "confluent_access_point" "default" {
  display_name = "${var.aws_db_vpc_id}-rds-${var.aws_rds_mysql_instance_name}-ap"
  environment {
    id = confluent_environment.default.id
  }
  gateway {
    id = confluent_gateway.default.id
  }
  aws_egress_private_link_endpoint {
    vpc_endpoint_service_name = aws_vpc_endpoint_service.nlb_endpoint_service.service_name
  }
}

# resource "confluent_dns_record" "default" {
#   display_name = "${var.aws_db_vpc_id}-rds"
#   environment {
#     id = confluent_environment.default.id
#   }
#   domain = tolist(aws_vpc_endpoint_service.nlb_endpoint_service.base_endpoint_dns_names)[0]
#   gateway {
#     id = confluent_gateway.default.id
#   }
#   private_link_access_point {
#     id = confluent_access_point.default.id
#   }
# }