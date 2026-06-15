---
name: Verify / Certificate issue
about: Problems with the verify command, progress tracking, or certificate export
title: "[VERIFY] "
labels: bug
assignees: madebygps, rishabkumar7

---

**What's the problem?**
- [ ] `verify` command not found
- [ ] Progress count is wrong (e.g. stuck at 17/18)
- [ ] Flag is correct but verify says it's wrong
- [ ] Certificate export (`verify export`) not working
- [ ] Token not accepted on learntocloud.guide

**Cloud Provider:**
- [ ] AWS
- [ ] Azure
- [ ] GCP

**Verify command output:**
```
<paste the output of your verify command here>
```

**Progress output** (run `verify progress`):
```
<paste output here>
```

**Have you tried:**
- [ ] Running `verify 0 CTF{example}` first (this is required)
- [ ] Double-checking flag format is exactly `CTF{...}` with no extra spaces
- [ ] Running `verify list` to see all challenge statuses
