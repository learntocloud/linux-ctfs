# Linux Command Line CTF Lab - GCP

> [!IMPORTANT]
> Please complete [Phase 1 Guide](https://learntocloud.guide/phase/1) before attempting these challenges. Do not share solutions publicly - focus on sharing your learning journey instead.

Deploy the lab here, then follow the [Playing the Lab guide](../GUIDE.md) to connect, capture flags, and export your certificate.

## Contents

- [Prerequisites](#prerequisites)
- [Deploy the Lab](#deploy-the-lab)
- [Play the Lab](#play-the-lab)
- [Pause the Lab](#pause-the-lab)
- [Clean Up](#clean-up)
- [Troubleshooting](#troubleshooting)

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) (v1.9.0 or later)
2. [gcloud CLI](https://cloud.google.com/sdk/docs/install)
3. A Google Cloud account with a project and billing enabled
4. A GitHub fork of this repository

## Deploy the Lab

1. Clone your fork:

    ```sh
    git clone https://github.com/<your-github-username>/linux-ctfs
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

    Replace the values with your project ID and preferred region/zone (defaults to us-central1/us-central1-a). Type `yes` when prompted.

4. Note the `public_ip_address` output. You'll use it to connect.

If deployment fails, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md#gcp).

## Play the Lab

Continue with the [Playing the Lab guide](../GUIDE.md): connect over SSH, capture flags, and export your completion token.

## Pause the Lab

To reduce cost while you're away, stop the VM. Use the same zone you deployed to (default `us-central1-a`).

```sh
gcloud compute instances stop ctf-instance --zone=YOUR_GCP_ZONE
```

Start it again:

```sh
gcloud compute instances start ctf-instance --zone=YOUR_GCP_ZONE
```

This lab uses an ephemeral public IP, so it may change after a restart. Look up the new one:

```sh
gcloud compute instances describe ctf-instance \
  --zone=YOUR_GCP_ZONE \
  --format="value(networkInterfaces[0].accessConfigs[0].natIP)"
```

If you see a "Remote host identification has changed" warning, remove the old key and reconnect:

```sh
ssh-keygen -R <public_ip_address>
ssh ctf_user@<public_ip_address>
```

> [!NOTE]
> `verify time` uses wall clock time, so stopped time still counts.

## Clean Up

Save your completion token first: destroying the lab deletes the VM and everything on it. Then destroy the resources to avoid charges:

```sh
terraform destroy
```

Type `yes` when prompted.

## Troubleshooting

Most `terraform apply` failures come from missing gcloud authentication (both `auth login` steps), an old Terraform version, a project without billing enabled, or missing permissions to create Compute Engine instances and firewall rules.

See the [GCP section of TROUBLESHOOTING.md](../TROUBLESHOOTING.md#gcp). If problems persist, [open an issue](../TROUBLESHOOTING.md#getting-help--reporting-issues).
