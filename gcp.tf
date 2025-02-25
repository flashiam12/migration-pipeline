data "google_project" "default"{
  project_id = var.gcp_project_id
}
resource "google_project_iam_binding" "bigquery_admin" {
  project = var.gcp_project_id
  role    = "roles/bigquery.admin"

  members = [
    "serviceAccount:${var.gcp_bq_service_account_name}@${var.gcp_project_id}.iam.gserviceaccount.com"
  ]
}

resource "google_project_iam_binding" "bigquery_data_editor" {
  project = "sales-engineering-206314"
  role    = "roles/bigquery.dataEditor"

  members = [
    "serviceAccount:${var.gcp_bq_service_account_name}@${var.gcp_project_id}.iam.gserviceaccount.com"
  ]
}

resource "google_project_iam_binding" "bigquery_data_viewer" {
  project = "sales-engineering-206314"
  role    = "roles/bigquery.dataViewer"

  members = [
    "serviceAccount:${var.gcp_bq_service_account_name}@${var.gcp_project_id}.iam.gserviceaccount.com"
  ]
}

resource "google_project_iam_binding" "bigquery_data_owner" {
  project = "sales-engineering-206314"
  role    = "roles/bigquery.dataOwner"

  members = [
    "serviceAccount:${var.gcp_bq_service_account_name}@${var.gcp_project_id}.iam.gserviceaccount.com"
  ]
}

data "google_bigquery_dataset" "dataset" {
  dataset_id = var.gcp_bigquery_dataset
  project = var.gcp_project_id
}