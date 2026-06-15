---
name: SSH / Connection issue
about: Report problems connecting to the CTF VM via SSH
title: "[SSH] "
labels: bug, DevOps
assignees: madebygps, rishabkumar7

---

**Cloud Provider:**
- [ ] AWS
- [ ] Azure
- [ ] GCP

**Connection method:**
Password authentication (using `CTFpassword123!`)

**SSH command used:**
```
<paste your ssh command here>
```

**Error message:**
```
<paste the error output here>
```

**Checklist:**
- [ ] Terraform apply completed successfully
- [ ] I waited at least 2-3 minutes after `terraform apply` for setup to finish
- [ ] I'm using the correct public IP from terraform output
- [ ] I'm connecting as `ctf_user` (not `root`, `ubuntu`, or `ec2-user`)
- [ ] I can see the VM is running in my cloud provider's console

**Additional context:**
Are you behind a VPN, corporate firewall, or on a restricted network?
