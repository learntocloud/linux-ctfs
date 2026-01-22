---
name: ctf-challenge-creator
description: Create a new Linux CTF challenge. Use when user wants to add a challenge, create a puzzle, or expand the CTF. Guides through the full workflow from concept to validation.
---

# CTF Challenge Creator

Step-by-step workflow for creating ONE new Linux CTF challenge.

## Step 1: Identify What Exists

Read `README.md` to see the current challenge table. Identify:
- What challenges already exist (currently 18)
- What Linux concepts are already covered
- What difficulty levels have gaps
- The next available challenge number

## Step 2: Design the Challenge Concept

Ask the user (if not specified):
- What Linux command or concept should this teach?
- What difficulty level? (⭐ Beginner, ⭐⭐ Intermediate, ⭐⭐⭐ Advanced)

Ensure the concept doesn't overlap with existing challenges.

## Step 3: Research the Command

Before writing the hint, research the Linux command properly:
- Use `man <command>` documentation or search for authoritative sources
- Understand the common use cases
- Identify what learners often struggle with
- Find the specific flags/options relevant to this challenge

This research informs both the challenge design AND the educational hint.

## Step 4: Create the Challenge

Read `ctf_setup.sh` to understand existing patterns, then add:

1. **FLAG_BASES array** (~line 24): Add `[N]="concept_name"`
2. **Setup section** (before "Set permissions"): Add the challenge setup code
3. **CHALLENGE_NAMES array** (~line 165 in verify script): Add the challenge name
4. **CHALLENGE_HINTS array** (in verify script): Add educational hint

Use existing challenge patterns as templates - read them from the file.

## Step 5: Write the Hint

The hint must:
- Teach the concept WITHOUT giving away the exact solution
- Reference `man` pages or general techniques
- Guide learners toward discovery, not answers

Example of good vs bad:
- ❌ "Use `find /opt -perm 777` to locate the file"
- ✅ "The `find` command can search by many attributes. Check `man find` for permission-related options."

## Step 6: Update Documentation

Add a row to the challenge table in `README.md`:
```
| N | Challenge Name | ⭐⭐ | command, concept |
```

Update any count references from "18" to the new total.

## Step 7: Add Tests

Read `test_ctf_challenges.sh` for patterns, then add:
- Setup verification test (file exists, service running, etc.)
- Solution test that extracts the flag
- Flag verification call

## Step 8: Validate

Use the **ctf-testing** skill:
```
Use the ctf-testing skill to deploy to Azure and validate all challenges
```

## Checklist Before Done

- [ ] FLAG_BASES has new entry
- [ ] Setup section creates the challenge
- [ ] CHALLENGE_NAMES has new entry  
- [ ] CHALLENGE_HINTS has educational hint
- [ ] README.md table updated
- [ ] test_ctf_challenges.sh has tests
- [ ] All "18" counts updated if adding (not replacing)
- [ ] Validated with ctf-testing skill
