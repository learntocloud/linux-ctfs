# Linux Command Line CTF Lab - AWS

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

1. [Terraform](https://www.terraform.io/downloads.html) (v1.9.0 or later)
2. [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials
3. A GitHub fork of this repository

### Windows

Run the AWS Terraform deployment from [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/windows/wsl/install). AWS release-mode readiness uses a local `/bin/sh` script to wait for Systems Manager Run Command, so native Windows PowerShell and Command Prompt are not currently supported.

Install Terraform and the AWS CLI inside your WSL distribution, then configure AWS credentials there before continuing:

```sh
aws configure
aws sts get-caller-identity
```

Credentials configured only in Windows PowerShell are not automatically available inside WSL.

## Deploy the Lab

1. Clone your fork:

    ```sh
    git clone https://github.com/<your-github-username>/linux-ctfs
    cd linux-ctfs/aws
    ```

2. Initialize and apply Terraform with an AWS region enabled for your account (for example `us-east-1`):

    ```sh
    terraform init
    terraform apply -var="aws_region=us-east-1"
    ```

    Type `yes` when prompted. You can also set `aws_region = "us-east-1"` in a `terraform.tfvars` file and run `terraform apply` without `-var`.

    <details>
    <summary>Not sure which regions are enabled for your account?</summary>

    ```sh
    aws ec2 describe-regions \
      --region us-east-1 \
      --all-regions \
      --query "Regions[?OptInStatus=='opt-in-not-required' || OptInStatus=='opted-in'].{Name:RegionName,Status:OptInStatus}" \
      --output table
    ```

    </details>

3. Note the `public_ip_address` output. You'll use it to connect.

If deployment fails, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md#aws).

## Play the Lab

Continue with the [Playing the Lab guide](../GUIDE.md): connect over SSH, capture flags, and export your completion token.

## Pause the Lab

To reduce cost while you're away, stop the VM:

```sh
terraform apply -var="aws_region=<your-region>" -var ctf_instance_state="stopped" -auto-approve
```

Start it again:

```sh
terraform apply -var="aws_region=<your-region>" -var ctf_instance_state="running" -auto-approve
```

This module uses an ephemeral public IP, so it may change after a restart. Look up the new one:

```sh
terraform output public_ip_address
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
terraform destroy -var="aws_region=<your-region>"
```

Type `yes` when prompted.

## Troubleshooting

Most `terraform apply` failures come from missing credentials (`aws sts get-caller-identity` should succeed), an old Terraform version, or missing permissions for EC2, VPC, Security Groups, IAM role/profile, and SSM Run Command.

Release mode uses Systems Manager to wait for setup readiness, so a failure while waiting is covered in [AWS: SSM setup readiness errors](../TROUBLESHOOTING.md#aws-ssm-setup-readiness-errors). For region, quota, and organization policy errors, see the [AWS section of TROUBLESHOOTING.md](../TROUBLESHOOTING.md#aws). If problems persist, [open an issue](../TROUBLESHOOTING.md#getting-help--reporting-issues).
