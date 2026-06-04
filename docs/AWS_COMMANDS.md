# AWS Commands

Use these commands to discover an enabled AWS region first, then run Terraform with an explicit region and instance type.

## Check enabled regions

```sh
aws ec2 describe-regions \
  --region us-east-1 \
  --all-regions \
  --query "Regions[?OptInStatus=='opt-in-not-required' || OptInStatus=='opted-in'].{Name:RegionName,Status:OptInStatus}" \
  --output table
```

Choose a region where `Status` is `opt-in-not-required` or `opted-in`.

## Export variables

```sh
export AWS_REGION=us-east-1
export AWS_INSTANCE_TYPE=t3.micro
```

## Run Terraform

```sh
cd aws
terraform init
terraform apply \
  -var="aws_region=$AWS_REGION" \
  -var="aws_instance_type=$AWS_INSTANCE_TYPE"
```

## Troubleshooting

If deployment fails, see [TROUBLESHOOTING.md](../TROUBLESHOOTING.md).
