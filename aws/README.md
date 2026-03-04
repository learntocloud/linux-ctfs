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

2. (Optional) Modify the AWS region by creating a `terraform.tfvars` file:

    ```sh
    aws_region = "us-east-1"
    ```

3. Initialize and apply Terraform:

    ```sh
    terraform init
    terraform apply
    ```

    Type `yes` when prompted.

4. Note the `public_ip_address` output—you'll use this to connect.

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
- Whether SSH fails or the issue happens after login (e.g., `verify progress`)

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
