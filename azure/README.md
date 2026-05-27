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

    By default, Terraform uses release mode. The VM downloads the setup package from the latest GitHub Release, verifies its SHA-256 checksum, and runs setup during first boot.

    Maintainers can choose a specific setup release if they need to pin or roll back the setup package:

    ```sh
    terraform apply \
      -var subscription_id="YOUR_AZURE_SUBSCRIPTION_ID" \
      -var az_region="YOUR_AZURE_REGION" \
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

## Starting/Stopping the Lab VM

If you'd like to pause the lab, you can utilize the following commands to start or stop the VM and reduce lab cost:

To power off the VM:

1. exit from the SSH session:

    ```sh
    exit
    ```
 2. Use the following commands to power off or on the VM:
```sh
# power off
terraform apply -invoke=action.azurerm_virtual_machine_power.ctf_power_off 
3. Type `yes` when prompted.

To power on the VM:
1. Use the following command to power on the VM:
```sh
terraform apply -invoke=action.azurerm_virtual_machine_power.ctf_power_on 
```

1. type `yes` when prompted.
1. Connect to the VM via SSH:
    ```sh
    ssh ctf_user@<public_ip_address>
    ```

> [!NOTE]
> `verify time` uses wall clock elapsed time. If the lab is powered off before you complete and export, powered-off time still counts in elapsed time.



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
- If SSH works but the lab is not ready, check `/var/log/ctf_setup.log`, `/var/lib/cloud/instance/ctf-setup.done`, `/var/lib/linux-ctfs/setup.done`, and `/var/lib/linux-ctfs/setup.failed`

### Changing Setup Versions

The setup script runs during first boot. If you change `setup_release_tag` after a VM already exists, or if the default `latest` release changes, recreate the VM so first-boot setup runs with the new package.

### VM Size / Capacity Errors

If you encounter an error like:

```text
SkuNotAvailable: The requested VM size ... is currently not available in location "your location"
```

This is usually due to regional capacity restrictions, subscription limits, or VM quota in the selected region. The default VM size is `Standard_B1s`, and the default region is `East US`.

Check whether `Standard_B1s` is available in a region:

```sh
az vm list-skus \
  --location eastus \
  --resource-type virtualMachines \
  --size Standard_B1s \
  --all \
  --query "[?name=='Standard_B1s'].{name:name, restrictions:restrictions}" \
  -o json
```

If `restrictions` is `[]`, Azure reports that SKU as available for your subscription in that region. If restrictions are returned, try another region or VM size.

Check VM quota in a region:

```sh
az vm list-usage --location eastus -o table
```

To check several common regions:

```sh
for region in eastus southcentralus westus; do
  echo "== $region =="
  az vm list-skus \
    --location "$region" \
    --resource-type virtualMachines \
    --size Standard_B1s \
    --all \
    --query "[?name=='Standard_B1s'].{name:name, restrictions:restrictions}" \
    -o json
  az vm list-usage --location "$region" -o table
done
```

If your selected region is restricted, retry with a known available region:

```sh
terraform apply \
  -var subscription_id="YOUR_AZURE_SUBSCRIPTION_ID" \
  -var az_region="eastus"
```

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
