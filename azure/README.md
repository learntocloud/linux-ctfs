# Linux Command Line CTF Lab - Azure

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

1. [Terraform](https://developer.hashicorp.com/terraform/install) (v1.14.0 or later)
2. [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
3. An Azure account with an active subscription
4. A GitHub fork of this repository

> [!NOTE]
> If you have an Azure Student account, you may encounter errors. See [this workaround](https://github.com/g-now-zero/l2c-guides/blob/main/posts/ctf-azure-spot-instances-guide.md).

## Deploy the Lab

1. Clone your fork:

    ```sh
    git clone https://github.com/<your-github-username>/linux-ctfs
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

    Replace the values with your subscription ID and preferred region (defaults to East US). Type `yes` when prompted.

4. Note the `public_ip_address` output. You'll use it to connect.

If deployment fails, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md#azure).

### VM size / capacity errors

If `terraform apply` fails with `SkuNotAvailable` or quota/capacity errors, switching region and/or VM size (`azure_vm_size`, default `Standard_B1s`) is usually the fastest fix. See:

- [Azure: SkuNotAvailable / Capacity errors](../TROUBLESHOOTING.md#azure-skunotavailable--capacity-errors)
- [Azure: Quota limit errors](../TROUBLESHOOTING.md#azure-quota-limit-errors)

## Play the Lab

Continue with the [Playing the Lab guide](../GUIDE.md): connect over SSH, capture flags, and export your completion token.

## Pause the Lab

To reduce cost while you're away, power off the VM:

```sh
terraform apply -invoke=action.azurerm_virtual_machine_power.ctf_power_off
```

Power it back on:

```sh
terraform apply -invoke=action.azurerm_virtual_machine_power.ctf_power_on
```

Type `yes` when prompted for each. Then reconnect with `ssh ctf_user@<public_ip_address>`.

> [!NOTE]
> `verify time` uses wall clock time, so powered-off time still counts.

## Clean Up

Save your completion token first: destroying the lab deletes the VM and everything on it. Then destroy the resources to avoid charges:

```sh
terraform destroy
```

Type `yes` when prompted.

## Troubleshooting

Most `terraform apply` failures come from an expired `az login`, an old Terraform version, or missing permissions to create VMs, VNets, and Network Security Groups.

If release setup fails, Azure reports it through the VM Custom Script Extension. Useful VM-side logs:

```text
/var/log/ctf_setup.log
/var/log/waagent.log
/var/log/azure/custom-script/handler.log
```

For SKU, capacity, and quota errors, see the [Azure section of TROUBLESHOOTING.md](../TROUBLESHOOTING.md#azure). If problems persist, [open an issue](../TROUBLESHOOTING.md#getting-help--reporting-issues).
