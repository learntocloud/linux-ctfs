#!/bin/bash
# Destroys all CTF lab resources EXCEPT the persistent EBS volume (CTF Lab Data)

echo "Destroying CTF Lab resources (EBS volume will be preserved)..."

terraform destroy \
  -target=aws_volume_attachment.ctf_data_attach \
  -target=null_resource.wait_for_setup \
  -target=aws_instance.ctf_instance \
  -target=aws_security_group.ctf_sg \
  -target=aws_route_table_association.ctf_route_table_assoc \
  -target=aws_route_table.ctf_route_table \
  -target=aws_subnet.ctf_subnet \
  -target=aws_internet_gateway.ctf_igw \
  -target=aws_vpc.ctf_vpc \
  -auto-approve

echo ""
echo "Done! EBS volume preserved: $(terraform output -raw ctf_ebs_volume_id 2>/dev/null || echo 'check AWS console')"
echo "Remember to set existing_ebs_volume_id in terraform.tfvars before next apply."
