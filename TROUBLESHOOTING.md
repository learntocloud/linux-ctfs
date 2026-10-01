# TROUBLESHOOTING

This guide shows examples of errors you might see when deploying or using the linux-ctfs lab, and how to fix them using simple commands.

- [Lab not ready after SSH login](#lab-not-ready-after-ssh-login)
- [Completion token not accepted](#completion-token-not-accepted)
- [Getting Help / Reporting Issues](#getting-help--reporting-issues)
- [AWS](#aws)
- [AWS: Region / endpoint / Auth errors](#aws-region--endpoint--auth-errors)
- [AWS: Quota / vCPU limit errors](#aws-quota--vcpu-limit-errors)
- [AWS: Instance type not offered / Insufficient capacity errors](#aws-instance-type-not-offered--insufficient-capacity-errors)
- [AWS: SSM setup readiness errors](#aws-ssm-setup-readiness-errors)
- [AWS: Service Control Policy (SCP) / Explicit deny errors](#aws-service-control-policy-scp--explicit-deny-errors)
- [Azure](#azure)
- [Azure: SkuNotAvailable / Capacity errors](#azure-skunotavailable--capacity-errors)
- [Azure: Quota limit errors](#azure-quota-limit-errors)
- [Azure: Azure for Students errors](#azure-azure-for-students-errors)
- [Azure: Resource group already exists](#azure-resource-group-already-exists)
- [GCP](#gcp)
- [GCP: API not enabled / Billing errors](#gcp-api-not-enabled--billing-errors)
- [GCP: Machine type not offered / Zone capacity errors](#gcp-machine-type-not-offered--zone-capacity-errors)
- [GCP: Quota errors](#gcp-quota-errors)
- [GCP: Organization policy errors](#gcp-organization-policy-errors)
- [GCP: Setup readiness errors](#gcp-setup-readiness-errors)

## Lab not ready after SSH login

If you can SSH in but `verify` isn't found or challenges seem to be missing, setup may still be running or may have failed. Wait a minute, log in again, and if it still isn't ready, check the setup status on the VM:

- `/var/lib/linux-ctfs/setup.done` exists when setup finished successfully.
- `/var/lib/linux-ctfs/setup.failed` exists if setup failed.
- `/var/lib/cloud/instance/ctf-setup.done` is the cloud-init completion marker.
- `/var/log/ctf_setup.log` has the setup log.

If setup failed, run `terraform destroy` and then `terraform apply` to redeploy. If it fails again, [open an issue](#getting-help--reporting-issues) and include the end of `/var/log/ctf_setup.log`.

## Completion token not accepted

Some terminals truncate long lines when copying. If your token isn't being accepted, it may be incomplete. The full token should be around **300+ characters**.

1. **Check the length:**
   ```bash
   verify export <your-github-username> 2>/dev/null | sed -n '/BEGIN/,/END/{/BEGIN\|END/d;p}' | wc -c
   ```
   If the result is less than 300, your terminal is truncating the token.

2. **Save it to a file:**
   ```bash
   verify export <your-github-username> 2>/dev/null | sed -n '/BEGIN/,/END/{/BEGIN\|END/d;p}' > ~/token.txt
   ```

3. **Open in nano and compare:**
   ```bash
   nano ~/token.txt
   ```
   `nano` will word-wrap properly. Does it match what you see in terminal? If it's longer in `nano`, your terminal was truncating it, so use the full value from `nano`.

4. **Check your username:** The username you exported with must match your GitHub username exactly—no `@` symbol, no extra spaces.

5. **Still not working?** Open a [GitHub issue](https://github.com/learntocloud/linux-ctfs/issues) with the output of `wc -c ~/token.txt`.

## Getting Help / Reporting Issues

If you're having trouble deploying or accessing the lab (Terraform errors, cloud permissions, SSH issues, the `verify` command not working), please **open a GitHub issue**:

https://github.com/learntocloud/linux-ctfs/issues

To help us troubleshoot quickly, include:

- Cloud provider (AWS/Azure/GCP) and region/zone
- Your OS and terminal (Windows/macOS/Linux, WSL, etc.)
- `terraform version`
- CLI status/output confirming you're authenticated (`aws sts get-caller-identity`, `az account show`, or `gcloud auth list --filter=status:ACTIVE`)
- The command you ran and the **exact error output** (redact any secrets)
- Whether the failure is during `terraform apply`, SSH connection, or inside the VM (e.g., `verify progress`)
- If SSH works but the lab is not ready, the setup status files listed in [Lab not ready after SSH login](#lab-not-ready-after-ssh-login)

Please only open issues about the lab infrastructure, not for help completing challenges—use `verify hint <challenge_number>` instead.

## AWS

<!-- Placeholder for future screenshots: ![AWS troubleshooting screenshot](docs/images/aws-troubleshooting.png) -->

The Terraform commands in this AWS section assume you are running them from the `aws/` directory.

On Windows, run the AWS deployment from WSL. The release-mode Systems Manager readiness check requires `/bin/sh` and is not supported from native PowerShell or Command Prompt. Install Terraform and the AWS CLI inside WSL, then confirm that WSL can access your AWS credentials:

```sh
aws sts get-caller-identity
```

If AWS CLI works in Windows but not in WSL, configure credentials inside WSL with `aws configure`.

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

First, check whether instances from an earlier deploy are still running and using your quota:

```sh
aws ec2 describe-instances \
  --region us-east-1 \
  --filters Name=instance-state-name,Values=pending,running \
  --query "Reservations[].Instances[].{Id:InstanceId,Type:InstanceType,State:State.Name}" \
  --output table
```

If you find old lab instances, run `terraform destroy` from the directory that created them.

The default instance type, `t3.micro`, uses 2 vCPUs. `t2.micro` uses 1 vCPU, so it fits in a smaller quota:

```sh
terraform apply -var="aws_instance_type=t2.micro"
```

If that still fails, request a quota increase for **Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances** in the [Service Quotas console](https://console.aws.amazon.com/servicequotas/home/services/ec2/quotas) for the region you are deploying to. New accounts can take a while to get approved.

### AWS: Instance type not offered / Insufficient capacity errors

Terraform picks an availability zone that offers your instance type. If no zone in the region offers it, `terraform plan` stops with:

```text
Instance type <type> is not offered in any availability zone in <region>.
```

If the zone is offered but AWS is temporarily out of capacity, `terraform apply` may fail with:

```text
InsufficientInstanceCapacity
```

To see which instance types are offered in a region:

```sh
aws ec2 describe-instance-type-offerings \
  --region us-east-1 \
  --location-type region \
  --filters Name=instance-type,Values=t2.micro,t3.micro \
  --output table
```

Then retry with an instance type from that list, or with a different region:

```sh
terraform apply -var="aws_instance_type=t2.micro"
```

```sh
terraform apply -var="aws_region=us-east-2"
```

For `InsufficientInstanceCapacity`, waiting a few minutes and running `terraform apply` again often works.

If you are trying to stay in the AWS Free Tier, which instance types are eligible depends on your account and region. Check the **Free Tier** page in the AWS Billing console before choosing one.

### AWS: SSM setup readiness errors

AWS release mode uses Systems Manager to wait for setup readiness. If Terraform fails while waiting on `null_resource.release_setup_ready`, check whether the instance became an SSM managed node and whether the SSM Run Command completed.

Useful checks:

```sh
aws ssm describe-instance-information \
  --region us-east-1 \
  --filters Key=InstanceIds,Values=<instance_id>
```

```sh
aws ssm list-command-invocations \
  --region us-east-1 \
  --instance-id <instance_id> \
  --details
```

Common causes:

- Terraform is running from native Windows PowerShell or Command Prompt instead of WSL.
- The Terraform caller cannot create IAM roles, IAM instance profiles, or send/read SSM commands.
- The generated SSM instance profile is not attached to the EC2 instance.
- SSM Agent is not running yet on the VM.
- Account-level SSM maintenance commands are still running during first boot.
- The instance cannot reach Systems Manager endpoints over outbound HTTPS.
- Setup failed before writing `/var/lib/linux-ctfs/setup.done`; check `/var/log/cloud-init-output.log` and `/var/log/ctf_setup.log`.

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

The default VM size is `Standard_B1s`, and the default region is `East US`. The lab uses an x64 Ubuntu image, so the VM size must be x64. Arm64 sizes such as `Standard_B2pts_v2` won't work.

### Azure: SkuNotAvailable / Capacity errors

`terraform plan` checks the VM size before creating anything. If the size can't be used, it stops with one of these messages:

```text
VM size <size> is not offered in <region>.
```

```text
VM size <size> is not available for your subscription in <region> (NotAvailableForSubscription).
```

The second one is common on Azure for Students, where `Standard_B1s` is often restricted in `East US`. Switch region or VM size and retry.

If the check passes but `terraform apply` still fails with an error like:

```text
SkuNotAvailable: The requested VM size ... is currently not available in location "your location"
```

the region is temporarily out of capacity for that size. Retry later, or switch region or VM size.

To find a size that works, x64 sizes that are small enough for the lab include `Standard_B1s`, `Standard_B1ms`, `Standard_B2s`, and `Standard_B2ats_v2`.

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

### Azure: Azure for Students errors

Azure for Students subscriptions have extra limits beyond VM size restrictions.

**Allowed regions.** Many Student subscriptions only allow deployments to a small set of regions. Deploying elsewhere fails with an error like:

```text
RequestDisallowedByAzure: Resource 'ctf-resources' was disallowed by Azure: This policy maintains a set of best available regions where your subscription can deploy resources.
```

List the regions your subscription allows:

```sh
az policy assignment list \
  --subscription "YOUR_AZURE_SUBSCRIPTION_ID" \
  --disable-scope-strict-match \
  --query "[].parameters.listOfAllowedLocations.value" \
  -o json
```

If that prints an empty list, the restriction isn't visible to your account. Try another region, such as `eastus2`, `westus2`, or `centralus`.

Retry with an allowed region:

```sh
terraform apply \
  -var subscription_id="YOUR_AZURE_SUBSCRIPTION_ID" \
  -var az_region="eastus2"
```

**Credits used up.** When the Student credit runs out, the subscription is disabled and deployments fail with errors like `ReadOnlyDisabledSubscription`. Check the subscription state:

```sh
az account show --subscription "YOUR_AZURE_SUBSCRIPTION_ID" --query state -o tsv
```

If it isn't `Enabled`, check your remaining credit in the Azure portal under **Subscriptions**, or upgrade to Pay-As-You-Go.

### Azure: Resource group already exists

If Terraform fails with:

```text
A resource with the ID "/subscriptions/.../resourceGroups/ctf-resources" already exists
```

a lab from an earlier deploy is still there, but this Terraform directory has no record of it (for example, you deployed from another clone or deleted `terraform.tfstate`). Check what's in it first:

```sh
az resource list \
  --subscription "YOUR_AZURE_SUBSCRIPTION_ID" \
  --resource-group ctf-resources \
  -o table
```

If it only contains old lab resources, delete it and retry. This permanently deletes everything in the group:

```sh
az group delete --subscription "YOUR_AZURE_SUBSCRIPTION_ID" --name ctf-resources
```

## GCP

The Terraform commands in this GCP section assume you are running them from the `gcp/` directory. Add `-var gcp_project="YOUR_GCP_PROJECT_ID"` to each `terraform apply`.

The default machine type is `e2-micro`, and the default region is `us-central1`. If you don't set `gcp_zone`, Terraform picks the first zone in the region that offers the machine type. The `zone` output shows which one it used.

### GCP: API not enabled / Billing errors

On a new project, the first `terraform plan` or `apply` may fail with:

```text
Compute Engine API has not been used in project ... before or it is disabled.
```

Enable the Compute Engine API, wait a minute, then retry:

```sh
gcloud services enable compute.googleapis.com --project=YOUR_GCP_PROJECT_ID
```

If enabling the API fails with a billing error, or Terraform reports `billing account ... is disabled`, the project needs an active billing account. Check it with:

```sh
gcloud billing projects describe YOUR_GCP_PROJECT_ID
```

`billingEnabled` should be `true`. If it isn't, link a billing account in the Google Cloud console under **Billing**.

### GCP: Machine type not offered / Zone capacity errors

If no zone offers the machine type, `terraform plan` stops with:

```text
Machine type <type> is not offered in any zone in <region>.
```

If the zone offers it but Google Cloud is temporarily out of capacity, `terraform apply` may fail with:

```text
ZONE_RESOURCE_POOL_EXHAUSTED
```

To see which zones offer a machine type:

```sh
gcloud compute machine-types list \
  --filter="name=e2-micro" \
  --format="value(zone)" | sort
```

Then retry in another zone, or in another region and let Terraform pick the zone:

```sh
terraform apply -var gcp_project="YOUR_GCP_PROJECT_ID" -var gcp_zone="us-central1-b"
```

```sh
terraform apply -var gcp_project="YOUR_GCP_PROJECT_ID" -var gcp_region="us-east1"
```

If you set both `gcp_region` and `gcp_zone`, the zone must be in that region (for example `us-east1-b` for `us-east1`). Otherwise Terraform stops with a validation error.

If you are trying to stay in the Google Cloud Free Tier, `e2-micro` is only free in some US regions. Check the current [Free Tier limits](https://cloud.google.com/free/docs/free-cloud-features#compute) before choosing a region.

### GCP: Quota errors

If Terraform fails with an error like:

```text
Quota 'CPUS' exceeded.
```

```text
Quota 'IN_USE_ADDRESSES' exceeded.
```

Check whether instances from an earlier deploy are still running:

```sh
gcloud compute instances list --project=YOUR_GCP_PROJECT_ID
```

If you find old lab instances, run `terraform destroy` from the directory that created them. Otherwise, try another region or view and request quota increases in the Google Cloud console under **IAM & Admin > Quotas & System Limits**. Free trial accounts have lower quotas and some can't be increased until you upgrade the account.

### GCP: Organization policy errors

If your project belongs to an organization (for example a school or work account), organization policies can block the deployment even if you have permission. You may see errors that mention `constraints/`, such as:

```text
Constraint constraints/compute.vmExternalIpAccess violated
```

```text
Constraint constraints/gcp.resourceLocations violated
```

- `vmExternalIpAccess` blocks public IP addresses, which the lab needs for SSH.
- `resourceLocations` limits which regions you can use. Retry with an allowed `gcp_region`.

The linux-ctfs Terraform code cannot override these policies. Use a personal Google Cloud project, or ask your administrator which regions are allowed and whether VMs can have external IPs.

### GCP: Setup readiness errors

GCP runs the lab setup as a startup script and Terraform waits over SSH until it finishes. If Terraform fails or times out while waiting on `null_resource.release_setup_ready`, check the setup output.

If setup failed early, `ctf_user` may not exist yet, so the normal SSH login won't work. The startup script output is also written to the VM's serial console, which you can read without SSH:

```sh
gcloud compute instances get-serial-port-output ctf-instance \
  --zone="$(terraform output -raw zone)" | grep -i startup-script | tail -n 50
```

If `terraform output -raw zone` prints nothing, find the zone with `gcloud compute instances list`.

If you need a shell on the VM, `gcloud compute ssh` works even when `ctf_user` doesn't exist. It creates an SSH key on your computer and adds it to your project's metadata:

```sh
gcloud compute ssh ctf-instance --zone="$(terraform output -raw zone)"
```

Then check the setup logs:

```sh
sudo journalctl -u google-startup-scripts --no-pager | tail -n 50
```

```sh
sudo tail -n 50 /var/log/ctf_setup.log
```
