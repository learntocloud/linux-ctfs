# TROUBLESHOOTING

This guide shows examples of errors you might see when deploying the linux-ctfs lab, and how to fix them using simple commands.

- [AWS](#aws)
- [AWS: Region / endpoint / Auth errors](#aws-region--endpoint--auth-errors)
- [AWS: Quota / vCPU limit errors](#aws-quota--vcpu-limit-errors)
- [AWS: Service Control Policy (SCP) / Explicit deny errors](#aws-service-control-policy-scp--explicit-deny-errors)
- [Azure](#azure)
- [Azure: SkuNotAvailable / Capacity errors](#azure-skunotavailable--capacity-errors)
- [Azure: Quota limit errors](#azure-quota-limit-errors)
- [GCP](#gcp)

## AWS

<!-- Placeholder for future screenshots: ![AWS troubleshooting screenshot](docs/images/aws-troubleshooting.png) -->

The Terraform commands in this AWS section assume you are running them from the `aws/` directory.

Before your first AWS deploy, list the regions that are enabled for your account:

```sh
aws ec2 describe-regions \
  --region us-east-1 \
  --all-regions \
  --query "Regions[?OptInStatus=='opt-in-not-required' || OptInStatus=='opted-in'].{Name:RegionName,Status:OptInStatus}" \
  --output table
```

Choose a region where `Status` is `opt-in-not-required` or `opted-in`, then pass it to Terraform:

```sh
terraform apply -var="aws_region=us-east-1"
```

### AWS: Region / endpoint / Auth errors

Some AWS regions are disabled by default or require opt-in. If Terraform tries to deploy into one of those regions, you may see authentication or endpoint-related errors.

Example error snippets:

```text
AuthFailure
```

```text
Could not connect to the endpoint URL
```

If you see an Auth or endpoint error for a specific region, first list the enabled regions for your account:

```sh
aws ec2 describe-regions \
  --region us-east-1 \
  --all-regions \
  --query "Regions[?OptInStatus=='opt-in-not-required' || OptInStatus=='opted-in'].{Name:RegionName,Status:OptInStatus}" \
  --output table
```

Then retry with one of those enabled regions, for example `us-east-1`:

```sh
terraform apply -var="aws_region=us-east-1"
```

### AWS: Quota / vCPU limit errors

If your AWS account has a low EC2 quota in the selected region, Terraform may fail with errors like:

```text
VcpuLimitExceeded
```

```text
EC2 QUOTA EXCEEDED
```

This usually means the account does not have enough EC2 vCPU quota available in that region for the requested instance type.

Try a smaller instance type:

```sh
terraform apply -var="aws_instance_type=t3.micro"
```

If you need a larger size, you can request a quota increase in the AWS console for the region you want to use.

### AWS: Service Control Policy (SCP) / Explicit deny errors

A Service Control Policy (SCP) is an organization-level AWS policy that can block actions even if your IAM user or role normally has permission. The linux-ctfs Terraform code cannot override those restrictions.

You may see an error message that includes text like:

```text
explicit deny in a service control policy
```

If that happens, either:

- Use a personal AWS account that does not have strict organization policies.
- Ask your cloud administrator which regions and instance types are allowed, then retry with those values.

Example:

```sh
terraform apply \
  -var="aws_region=<allowed-region>" \
  -var="aws_instance_type=<allowed-instance-type>"
```

## Azure

The Terraform commands in this Azure section assume you are running them from the `azure/` directory.

The default VM size is `Standard_B1s`, and the default region is `East US`.

### Azure: SkuNotAvailable / Capacity errors

If Terraform fails with an error like:

```text
SkuNotAvailable: The requested VM size ... is currently not available in location "your location"
```

This usually means the selected region does not currently have capacity for that SKU, or your subscription is restricted in that region.

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

If `restrictions` is `[]`, the SKU is available for your subscription in that region. If restrictions are returned, switch region and retry.

To quickly compare common regions:

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
done
```

### Azure: Quota limit errors

If the SKU is available but deployment still fails, check VM usage/quota in the target region:

```sh
az vm list-usage --location eastus -o table
```

If usage is near the limit, either use another region or choose a different VM size.

Retry with a different region:

```sh
terraform apply \
  -var subscription_id="YOUR_AZURE_SUBSCRIPTION_ID" \
  -var az_region="southcentralus"
```

Or retry with a different VM size:

```sh
terraform apply \
  -var subscription_id="YOUR_AZURE_SUBSCRIPTION_ID" \
  -var azure_vm_size="Standard_B1ms"
```

## GCP

(Coming soon) - common deployment issues and how to adjust `gcp_machine_type`.
