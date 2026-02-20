# Linux Command Line CTF Lab - GCP

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) (v1.9.0 or later)
2. [gcloud CLI](https://cloud.google.com/sdk/docs/install)
3. A Google Cloud account with a project and billing enabled

## Getting Started

1. Clone this repository:

    ```sh
    git clone https://github.com/learntocloud/linux-ctfs
    cd linux-ctfs/gcp
    ```

2. Log in to Google Cloud:

    ```sh
    gcloud auth login
    gcloud auth application-default login
    ```

3. Initialize and apply Terraform:

    ```sh
    terraform init
    terraform apply \
      -var gcp_project="YOUR_GCP_PROJECT_ID" \
      -var gcp_region="YOUR_GCP_REGION" \
      -var gcp_zone="YOUR_GCP_ZONE"
    ```

    Replace the values with your project ID and preferred region/zone (defaults to us-central1/us-central1-a).

    Type `yes` when prompted.

4. Note the `public_ip_address` output—you'll use this to connect.


## Accessing the Lab

1. Connect via SSH:

    ```sh
    ssh ctf_user@<public_ip_address>
    ```

1. On first login you will be asked if you want to add fingerprints to the known hosts file; type `yes` and press Enter.

1. When prompted, enter the password: `CTFpassword123!`


## Cleaning Up

Destroy the resources when you're done to avoid charges:

```sh
terraform destroy
```

Type `yes` when prompted.

## Troubleshooting

1. Ensure your gcloud CLI is authenticated
2. Check that you're using Terraform v1.9.0 or later
3. Verify you have permissions to create Compute Engine instances and firewall rules

If problems persist, please open an issue:

https://github.com/learntocloud/linux-ctfs/issues

Include:
- GCP project + region/zone
- `terraform version`
- `gcloud auth list --filter=status:ACTIVE` output (no secrets)
- The exact `terraform apply` error output (redact any secrets)
- Whether SSH fails or the issue happens after login (e.g., `verify progress`)

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
