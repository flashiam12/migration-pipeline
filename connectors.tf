resource "confluent_connector" "source" {
  environment {
    id = confluent_environment.default.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.default.id
  }

  config_sensitive = {
    "database.user" =  var.aws_rds_mysql_user
    "database.password" = var.aws_rds_mysql_password
  }

  config_nonsensitive = {
    "connector.class"          = "MySqlCdcSourceV2"
    "name"                     = "mysql-rds-source-0"
    "database.hostname" =  data.aws_db_instance.default.address
    "database.port" =  data.aws_db_instance.default.port
    "output.data.format" = "JSON_SR"
    "tasks.max"                = "1"
    "topic.prefix" =  "${var.aws_rds_mysql_db}_mysql_rds_"
    "after.state.only" =  "false"
    "auto.restart.on.user.error" =  "true"
    "event.processing.failure.handling.mode" =  "warn"
    "ignore.default.for.nullables" =  "false"
    "inconsistent.schema.handling.mode" = "warn"
    "kafka.api.key": confluent_api_key.default.id
    "kafka.api.secret": confluent_api_key.default.secret
    "kafka.auth.mode"          = "KAFKA_API_KEY"
    "output.key.format" = "JSON_SR"
    "snapshot.locking.mode": "minimal"
    "snapshot.mode": "when_needed"
  }

  depends_on = [ confluent_role_binding.all-subjects-default-rb,
                 confluent_role_binding.cluster-admin 
  ]

  lifecycle {
    prevent_destroy = false
  }
}


resource "confluent_connector" "sink" {
  environment {
    id = confluent_environment.default.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.default.id
  }

  config_sensitive = {
    "keyfile" = file(var.gcp_bq_service_account_json_file)
  }

  config_nonsensitive = {
    "connector.class"          = "DataScienceBigQueryStorageSink"
    "name"                     = "bigquery-rds-source-0"
    "datasets" = data.google_bigquery_dataset.dataset.friendly_name
    "ingestion.mode" = "UPSERT"
    "project" = var.gcp_project_id
    "tasks.max" = "1"
    "auto.create.tables" = "true"
    "auto.restart.on.user.error" = "true"
    "auto.update.schemas" = "true"
    "commit.interval" = "3000 seconds"
    "input.data.format" = "JSON_SR"
    "input.key.format" = "JSON_SR"
    "kafka.api.key" = confluent_api_key.default.id
    "kafka.api.secret" = confluent_api_key.default.secret
    "kafka.auth.mode" = "KAFKA_API_KEY"
    "max.poll.records" = "500"
  }

  depends_on = [ confluent_role_binding.all-subjects-default-rb,
                 confluent_role_binding.cluster-admin 
  ]

  lifecycle {
    prevent_destroy = false
  }
}


# resource "confluent_kafka_connector" "bigquery_sink_v2" {
#   kafka_cluster {
#     id = "<KAFKA_CLUSTER_ID>"
#   }

#   environment {
#     id = "<ENVIRONMENT_ID>"
#   }

#   config = {
#     "name"                               = "bigquery-sink-v2"
#     "connector.class"                    = "BigQuerySinkV2"
#     "tasks.max"                          = "2"
#     "topics"                             = "<TOPICS>"
#     "auto.create.tables"                 = "true"
#     "default.dataset"                    = "<BIGQUERY_DATASET>"
#     "project.id"                         = "<BIGQUERY_PROJECT_ID>"
#     "keyfile"                            = file("<SERVICE_ACCOUNT_KEY_FILE>")
#     "buffer.mem.bytes"                   = "10000000"
#     "sanitize.topics"                    = "true"
#     "upsert.enabled"                     = "false"
#     "delete.enabled"                     = "false"
#     "key.converter"                      = "org.apache.kafka.connect.storage.StringConverter"
#     "value.converter"                    = "io.confluent.connect.avro.AvroConverter"
#     "value.converter.schema.registry.url" = "<SCHEMA_REGISTRY_URL>"
#   }
# }