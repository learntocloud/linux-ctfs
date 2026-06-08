# Linux Command Line CTF Lab - AWS

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) (v1.9.0 or later)
2. [AWS CLI](https://aws.amazon.com/cli/) configured with your credentials

## Getting Started

1. Clone this repository:

    ```sh
    git clone https://github.com/learntocloud/linux-ctfs
    cd linux-ctfs/aws
    ```

2. Check which AWS regions are enabled for your account:

```sh
aws ec2 describe-regions \
  --region us-east-1 \
  --all-regions \
  --query "Regions[?OptInStatus=='opt-in-not-required' || OptInStatus=='opted-in'].{Name:RegionName,Status:OptInStatus}" \
  --output table
```

3. Export one of the enabled regions before running Terraform:

    ```sh
    export AWS_REGION=us-east-1
    ```

4. (Optional) Set the AWS region in a `terraform.tfvars` file using one of the enabled regions:

    ```sh
    aws_region = "us-east-1"
    ```

    If you prefer not to use a `terraform.tfvars` file, you can pass the exported value directly to Terraform in the next step.

5. Initialize and apply Terraform:

    ```sh
    terraform init

    # If you set aws_region in terraform.tfvars
    terraform apply

    # Or, if you want to pass the exported region directly
    terraform apply -var="aws_region=$AWS_REGION"
    ```

    Type `yes` when prompted.

    If you run into errors when deploying, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) for common issues and fixes.

6. Note the `public_ip_address` output—you'll use this to connect.

## Accessing the Lab

1. Connect via SSH:

    ```sh
    ssh ctf_user@<public_ip_address>
    ```

1. On first login you will be asked if you want to add fingerprints to the known hosts file; type `yes` and press Enter.

1. When prompted, enter the password: `CTFpassword123!`

## Starting/Stopping the Lab VM

If you'd like to pause the lab, you can utilize the following commands to start or stop the VM and reduce lab cost:

```sh
# power off (stop instance)
terraform apply \
  -var ctf_instance_state="stopped" \
  -auto-approve

# power on (start instance)
terraform apply \
  -var ctf_instance_state="running" \
  -auto-approve
```

Note: This module uses an ephemeral public IP. After stopping/starting the instance, public_ip_address may change.

After a restart, check for a new IP.

```sh
terraform output public_ip_address
```
If you see a “Remote host identification has changed” warning after a restart, remove the old key, then reconnect:

```sh
# 1) Remove the old host key for that IP
ssh-keygen -R <public_ip>

# 2) Reconnect and accept the new key
ssh <user>@<public_ip>
```

> [!NOTE]
> `verify time` uses wall clock elapsed time. If the lab is stopped before you complete and export, stopped time still counts in elapsed time.

## Cleaning Up

Destroy the resources when you're done to avoid charges:

```sh
terraform destroy
```

Type `yes` when prompted.

## Troubleshooting

1. Ensure your AWS CLI is configured with valid credentials
2. Check that you're using Terraform v1.9.0 or later
3. Verify you have permissions to create EC2, VPC, and Security Group resources

If problems persist, please open an issue:

https://github.com/learntocloud/linux-ctfs/issues

Include:
- AWS region
- `terraform version`
- `aws sts get-caller-identity` output (no secrets)
- The exact `terraform apply` error output (redact any secrets)
- Whether SSH fails or the issue happens after login, such as when running `verify progress`

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
