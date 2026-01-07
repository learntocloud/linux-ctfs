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

If problems persist, please open an issue in this repository.

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
