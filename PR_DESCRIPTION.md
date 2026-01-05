## Summary

This PR adds 6 new challenges (13-18), improves the verify command with new features, and makes the lab reboot-resilient by converting background processes to systemd services.

## What's Changed

### New Challenges
- **Challenge 13: Cron Job Hunter** - Find a flag hidden in scheduled tasks
- **Challenge 14: Process Environment** - Extract a secret from a running process's environment variables
- **Challenge 15: Archive Archaeologist** - Dig through nested tar archives
- **Challenge 16: Symbolic Sleuth** - Follow a chain of symbolic links
- **Challenge 17: History Mystery** - Find a flag in bash history
- **Challenge 18: Disk Detective** - Discover a flag in filesystem metadata

### New Verify Features
- `verify list` - Show all challenges with completion status
- `verify hint [n]` - Get a hint for any challenge
- `verify time` - Track elapsed time (persists across reboots)
- `verify export` - Generate a completion certificate

### Infrastructure Improvements
- Converted all background services (challenges 6, 10, 12, 14) to systemd services for reboot resilience
- Consolidated `ctf_setup.sh` to root level, referenced by all cloud providers
- Updated challenge count from 12 to 18

## What to Review

1. **Test the new challenges** - Deploy on any cloud provider and verify challenges 13-18 work correctly
2. **Verify reboot resilience** - Reboot the VM and confirm services restart and progress is saved
3. **Check the hints** - Run `verify hint [1-18]` and confirm hints are helpful but not giving away answers
4. **Test the timer** - Verify `verify time` tracks elapsed wall-clock time correctly
5. **Documentation** - Review README updates for clarity and accuracy

## Testing Done

- [ ] Deployed on AWS
- [ ] Deployed on Azure  
- [ ] Deployed on GCP
- [ ] Tested VM reboot
- [ ] Completed all 18 challenges
