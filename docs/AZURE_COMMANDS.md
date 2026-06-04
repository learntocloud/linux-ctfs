# Azure Commands

Use these commands to choose your Azure subscription, region, and VM size before running Terraform.

## Sign in and get your subscription ID

```sh
az login
az account show --query id -o tsv
```

## Check VM size availability

```sh
az vm list-skus \
  --location eastus \
  --resource-type virtualMachines \
  --size Standard_B1s \
  --all \
  --query "[?name=='Standard_B1s'].{name:name, restrictions:restrictions}" \
  -o json
```

If `restrictions` is `[]`, that VM size is available for your subscription in that region.

## Export variables

```sh
export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
export AZURE_REGION="East US"
export AZURE_VM_SIZE="Standard_B1s"
```

## Run Terraform

```sh
cd azure
terraform init
terraform apply \
  -var="subscription_id=$AZURE_SUBSCRIPTION_ID" \
  -var="az_region=$AZURE_REGION" \
  -var="azure_vm_size=$AZURE_VM_SIZE"
```

## Troubleshooting

If deployment fails, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md).
