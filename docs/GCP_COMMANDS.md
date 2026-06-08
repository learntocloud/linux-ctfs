# GCP Commands

Use these commands to choose your GCP project, region, zone, and machine type before running Terraform.

## Sign in and check your active project

```sh
gcloud auth login
gcloud auth application-default login
gcloud config list project
```

## Check machine types in a zone

```sh
gcloud compute machine-types list --zones=us-central1-a
```

## Export variables

```sh
export GCP_PROJECT="<your-gcp-project-id>"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"
export GCP_MACHINE_TYPE="e2-micro"
```

## Run Terraform

```sh
cd gcp
terraform init
terraform apply \
  -var="gcp_project=$GCP_PROJECT" \
  -var="gcp_region=$GCP_REGION" \
  -var="gcp_zone=$GCP_ZONE" \
  -var="gcp_machine_type=$GCP_MACHINE_TYPE"
```

## Troubleshooting

If deployment fails, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md).
