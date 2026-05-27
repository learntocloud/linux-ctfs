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

    By default, Terraform uses release mode. The VM downloads the setup package from the latest GitHub Release, verifies its SHA-256 checksum, and runs setup during first boot.

    Maintainers can choose a specific setup release if they need to pin or roll back the setup package:

    ```sh
    terraform apply \
      -var gcp_project="YOUR_GCP_PROJECT_ID" \
      -var gcp_region="YOUR_GCP_REGION" \
      -var gcp_zone="YOUR_GCP_ZONE" \
      -var setup_release_tag="v0.1.0"
    ```

    If you are testing unmerged local setup changes, add `-var use_local_setup=true` to the `terraform apply` command. Contributor mode uploads your local setup files and uses SSH to run them on the VM.

4. Note the `public_ip_address` output—you'll use this to connect.


## Accessing the Lab

1. Connect via SSH:

    ```sh
    ssh ctf_user@<public_ip_address>
    ```

1. On first login you will be asked if you want to add fingerprints to the known hosts file; type `yes` and press Enter.

1. When prompted, enter the password: `CTFpassword123!`

## Timer Behavior

`verify time` uses wall clock elapsed time. The timer starts on your first challenge submission and freezes on your first successful `verify export` after 18/18.


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
- If SSH works but the lab is not ready, check `/var/log/ctf_setup.log`, `/var/lib/cloud/instance/ctf-setup.done`, `/var/lib/linux-ctfs/setup.done`, and `/var/lib/linux-ctfs/setup.failed`

### Changing Setup Versions

The setup script runs during first boot. If you change `setup_release_tag` after a VM already exists, or if the default `latest` release changes, recreate the VM so first-boot setup runs with the new package.

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
