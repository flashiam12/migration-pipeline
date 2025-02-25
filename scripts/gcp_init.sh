#! /bin/bash 

gcloud iam service-accounts create "bq-migration-test-shiv" \
    --description="Service account for BigQuery access" \
    --display-name="bq-migration-test-shiv"

gcloud projects add-iam-policy-binding sales-engineering-206314 \
    --member="serviceAccount:bq-migration-test-shiv@sales-engineering-206314.iam.gserviceaccount.com" \
    --role="roles/bigquery.admin"

gcloud projects add-iam-policy-binding sales-engineering-206314 \
    --member="serviceAccount:bq-migration-test-shiv@sales-engineering-206314.iam.gserviceaccount.com" \
    --role="roles/bigquery.dataEditor"

gcloud projects add-iam-policy-binding sales-engineering-206314 \
    --member="serviceAccount:bq-migration-test-shiv@sales-engineering-206314.iam.gserviceaccount.com" \
    --role="roles/bigquery.dataViewer"