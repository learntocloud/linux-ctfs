# Linux Command Line CTF Lab - Azure

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) (v1.14.0 or later)
2. [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
3. An Azure account with an active subscription

> [!NOTE]  
> If you have an Azure Student account, you may encounter errors. See [this workaround](https://github.com/g-now-zero/l2c-guides/blob/main/posts/ctf-azure-spot-instances-guide.md).

## Getting Started

1. Clone this repository:

    ```sh
    git clone https://github.com/learntocloud/linux-ctfs
    cd linux-ctfs/azure
    ```

2. Log in to Azure:

    ```sh
    az login
    ```

3. Initialize and apply Terraform:

    ```sh
    terraform init
    terraform apply \
      -var subscription_id="YOUR_AZURE_SUBSCRIPTION_ID" \
      -var az_region="YOUR_AZURE_REGION"
    ```

    Replace the values with your subscription ID and preferred region (defaults to East US).

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
# power off
terraform apply -invoke=action.azurerm_virtual_machine_power.ctf_power_off \
    -var subscription_id="YOUR_AZURE_SUBSCRIPTION_ID" \
    -var az_region="YOUR_AZURE_REGION" \
    -auto-approve
# power on
terraform apply -invoke=action.azurerm_virtual_machine_power.ctf_power_on \
    -var subscription_id="YOUR_AZURE_SUBSCRIPTION_ID" \
    -var az_region="YOUR_AZURE_REGION" \
    -auto-approve
```

## Cleaning Up

Destroy the resources when you're done to avoid charges:

```sh
terraform destroy
```

Type `yes` when prompted.

## Troubleshooting

1. Ensure your Azure CLI is logged in with valid credentials
2. Check that you're using Terraform v1.9.0 or later
3. Verify you have permissions to create VMs, VNets, and Network Security Groups

If problems persist, please open an issue:

https://github.com/learntocloud/linux-ctfs/issues

Include:
- Azure region
- `terraform version`
- `az account show` output (no secrets)
- The exact `terraform apply` error output (redact any secrets)
- Whether SSH fails or the issue happens after login (e.g., `verify progress`)

### VM Size / Capacity Errors (Free Azure Subscription)

If you encounter an error like:

SkuNotAvailable: The requested VM size ... is currently not available in location "your location"

This is usually due to regional capacity restrictions or limitations on free/trial subscriptions.

**Fix:**

1. Edit `main.tf` and change the VM size:

size = "Standard_B2ts_v2"

Use a region with available capacity (for example):

terraform apply -var="az_region=westeurope"

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
