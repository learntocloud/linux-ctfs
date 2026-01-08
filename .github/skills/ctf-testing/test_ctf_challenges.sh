#!/bin/bash
#
# CTF Challenge Test Script
# Runs on the VM to validate all challenges work correctly
#
# Usage:
#   ./test_ctf_challenges.sh [--with-reboot]
#
# Flags:
#   --with-reboot    After initial tests pass, creates a marker file and exits
#                    with code 100 to signal the orchestration script to reboot
#                    the VM. After reboot, re-run this script to verify services
#                    restarted and progress persisted.
#
# Exit codes:
#   0   - All tests passed
#   1   - One or more tests failed
#   100 - Reboot requested (only with --with-reboot flag, pre-reboot phase)
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
TOTAL=0

# Reboot marker file
REBOOT_MARKER="/tmp/.ctf_reboot_test_marker"
PROGRESS_SNAPSHOT="/tmp/.ctf_progress_snapshot"

# Parse arguments
WITH_REBOOT=false
for arg in "$@"; do
    case $arg in
        --with-reboot)
            WITH_REBOOT=true
            shift
            ;;
    esac
done

# Test helper functions
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASSED++)) || true
    ((TOTAL++)) || true
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAILED++)) || true
    ((TOTAL++)) || true
}

section() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if this is a post-reboot run
is_post_reboot() {
    [ -f "$REBOOT_MARKER" ]
}

# Run a test command and check result
run_test() {
    local description="$1"
    local command="$2"
    
    if eval "$command" &>/dev/null; then
        pass "$description"
    else
        fail "$description"
    fi
    # Always return 0 to prevent script exit with set -e
    return 0
}

# Run a test that checks command output contains expected string
run_test_output() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    local output
    output=$(eval "$command" 2>&1) || true
    
    if echo "$output" | grep -q "$expected"; then
        pass "$description"
    else
        fail "$description (expected: '$expected', got: '$output')"
    fi
    # Always return 0 to prevent script exit with set -e
    return 0
}

# ============================================================================
# POST-REBOOT VERIFICATION
# ============================================================================
if is_post_reboot; then
    section "POST-REBOOT VERIFICATION"
    
    echo "Detected reboot marker - running post-reboot checks..."
    
    # Check services survived reboot
    section "Service Survival Check"
    
    run_test "ctf-secret-service.service is active" \
        "systemctl is-active ctf-secret-service.service"
    
    run_test "ctf-monitor-directory.service is active" \
        "systemctl is-active ctf-monitor-directory.service"
    
    run_test "ctf-ping-message.service is active" \
        "systemctl is-active ctf-ping-message.service"
    
    run_test "ctf-secret-process.service is active" \
        "systemctl is-active ctf-secret-process.service"
    
    run_test "nginx.service is active" \
        "systemctl is-active nginx"
    
    # Check progress persisted
    section "Progress Persistence Check"
    
    if [ -f "$PROGRESS_SNAPSHOT" ]; then
        EXPECTED_COUNT=$(cat "$PROGRESS_SNAPSHOT")
        if [ -f ~/.completed_challenges ]; then
            ACTUAL_COUNT=$(sort -u ~/.completed_challenges | wc -l)
            if [ "$ACTUAL_COUNT" -ge "$EXPECTED_COUNT" ]; then
                pass "Progress persisted after reboot ($ACTUAL_COUNT challenges)"
            else
                fail "Progress lost after reboot (expected $EXPECTED_COUNT, got $ACTUAL_COUNT)"
            fi
        else
            fail "Progress file missing after reboot"
        fi
    else
        echo "No progress snapshot found - skipping persistence check"
    fi
    
    # Cleanup markers
    rm -f "$REBOOT_MARKER" "$PROGRESS_SNAPSHOT"
    
    # Print summary
    section "POST-REBOOT SUMMARY"
    echo "Passed: $PASSED"
    echo "Failed: $FAILED"
    echo "Total:  $TOTAL"
    
    if [ $FAILED -eq 0 ]; then
        echo -e "\n${GREEN}All post-reboot tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some post-reboot tests failed!${NC}"
        exit 1
    fi
fi

# ============================================================================
# MAIN TEST SUITE
# ============================================================================

section "VERIFY COMMAND TESTS"

# Test verify subcommands
run_test_output "verify 0 CTF{example} - accepts example flag" \
    "verify 0 CTF{example}" "✓"

run_test_output "verify progress - shows progress" \
    "verify progress" "Flags Found:"

run_test_output "verify list - shows challenge list" \
    "verify list" "Hidden File Discovery"

run_test_output "verify hint 1 - shows hint" \
    "verify hint 1" "Hidden files"

run_test_output "verify time - shows time or not started" \
    "verify time" "Time\|Timer"

run_test_output "verify export - requires all challenges (should fail)" \
    "verify export" "Complete all 18\|Congratulations"

run_test_output "verify with invalid challenge - shows error" \
    "verify 99 CTF{test} 2>&1" "Usage\|Invalid\|Error"

# ============================================================================
section "CHALLENGE SETUP VERIFICATION"
# ============================================================================

echo "Verifying all challenges are properly set up..."

# Challenge 1: Hidden File
run_test "Challenge 1 setup: .hidden_flag exists" \
    "test -f /home/ctf_user/ctf_challenges/.hidden_flag"

# Challenge 2: Secret File
run_test "Challenge 2 setup: secret_notes.txt exists" \
    "test -f /home/ctf_user/documents/projects/backup/secret_notes.txt"

# Challenge 3: Large Log
run_test "Challenge 3 setup: large_log_file.log exists and is large" \
    "test -f /var/log/large_log_file.log && test \$(stat -c%s /var/log/large_log_file.log) -gt 100000000"

# Challenge 4: User Investigation
run_test "Challenge 4 setup: flag_user exists with UID 1002" \
    "id flag_user && test \$(id -u flag_user) -eq 1002"

run_test "Challenge 4 setup: flag_user .profile exists" \
    "test -f /home/flag_user/.profile"

# Challenge 5: Permission Analysis
run_test "Challenge 5 setup: system.conf exists with 777 permissions" \
    "test -f /opt/systems/config/system.conf && test \$(stat -c%a /opt/systems/config/system.conf) = '777'"

# Challenge 6: Service Discovery
run_test "Challenge 6 setup: ctf-secret-service is active" \
    "systemctl is-active ctf-secret-service.service"

run_test "Challenge 6 setup: port 8080 is listening" \
    "ss -tulpn | grep -q :8080"

# Challenge 7: Encoding Challenge
run_test "Challenge 7 setup: encoded_flag.txt exists" \
    "test -f /home/ctf_user/ctf_challenges/encoded_flag.txt"

# Challenge 8: SSH Secrets
run_test "Challenge 8 setup: .ssh/secrets/backup/.authorized_keys exists" \
    "test -f /home/ctf_user/.ssh/secrets/backup/.authorized_keys"

# Challenge 9: DNS Troubleshooting
run_test "Challenge 9 setup: resolv.conf contains CTF flag" \
    "grep -q 'CTF{' /etc/resolv.conf"

# Challenge 10: Remote Upload Detection
run_test "Challenge 10 setup: ctf-monitor-directory service is active" \
    "systemctl is-active ctf-monitor-directory.service"

# Challenge 11: Web Configuration
run_test "Challenge 11 setup: nginx is active" \
    "systemctl is-active nginx"

run_test "Challenge 11 setup: port 8083 is listening" \
    "ss -tulpn | grep -q :8083"

run_test "Challenge 11 setup: index.html exists" \
    "test -f /var/www/html/index.html"

# Challenge 12: Network Traffic Analysis
run_test "Challenge 12 setup: ctf-ping-message service is active" \
    "systemctl is-active ctf-ping-message.service"

# Challenge 13: Cron Job Hunter
run_test "Challenge 13 setup: ctf_secret_task cron file exists" \
    "test -f /etc/cron.d/ctf_secret_task"

# Challenge 14: Process Environment
run_test "Challenge 14 setup: ctf-secret-process service is active" \
    "systemctl is-active ctf-secret-process.service"

run_test "Challenge 14 setup: ctf_secret_process is running" \
    "pgrep -f ctf_secret_process"

# Challenge 15: Archive Archaeologist
run_test "Challenge 15 setup: mystery_archive.tar.gz exists" \
    "test -f /home/ctf_user/ctf_challenges/mystery_archive.tar.gz"

# Challenge 16: Symbolic Sleuth
run_test "Challenge 16 setup: follow_me symlink exists" \
    "test -L /home/ctf_user/ctf_challenges/follow_me"

# Challenge 17: History Mystery
run_test "Challenge 17 setup: old_admin user exists" \
    "id old_admin"

run_test "Challenge 17 setup: old_admin .bash_history exists" \
    "test -f /home/old_admin/.bash_history"

# Challenge 18: Disk Detective
run_test "Challenge 18 setup: ctf_disk.img exists" \
    "test -f /opt/ctf_disk.img"

# ============================================================================
section "CHALLENGE SOLUTION TESTS"
# ============================================================================

echo "Testing that solution commands return flags (dynamic per-instance)..."

# Helper function to capture and verify a flag
# Args: challenge_num, description, solution_command
test_and_capture_flag() {
    local num="$1"
    local desc="$2"
    local cmd="$3"
    
    local flag
    # Use grep -a to treat binary files as text (needed for log files with binary data)
    flag=$(eval "$cmd" 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
    
    if [ -n "$flag" ]; then
        pass "Challenge $num solution: $desc returns flag"
        # Store for later verification
        eval "CAPTURED_FLAG_$num=\"$flag\""
    else
        fail "Challenge $num solution: $desc (no CTF flag found)"
        eval "CAPTURED_FLAG_$num=\"\""
    fi
}

# Challenge 1
test_and_capture_flag 1 "cat .hidden_flag" \
    "cat /home/ctf_user/ctf_challenges/.hidden_flag"

# Challenge 2
test_and_capture_flag 2 "cat secret_notes.txt" \
    "cat /home/ctf_user/documents/projects/backup/secret_notes.txt"

# Challenge 3
test_and_capture_flag 3 "tail large_log_file.log" \
    "tail -1 /var/log/large_log_file.log"

# Challenge 4
test_and_capture_flag 4 "cat flag_user .profile" \
    "cat /home/flag_user/.profile"

# Challenge 5
test_and_capture_flag 5 "cat system.conf" \
    "cat /opt/systems/config/system.conf"

# Challenge 6
test_and_capture_flag 6 "curl localhost:8080" \
    "curl -s --connect-timeout 5 --max-time 10 localhost:8080"

# Challenge 7
test_and_capture_flag 7 "double base64 decode" \
    "cat /home/ctf_user/ctf_challenges/encoded_flag.txt | base64 -d | base64 -d"

# Challenge 8
test_and_capture_flag 8 "cat .ssh hidden file" \
    "cat /home/ctf_user/.ssh/secrets/backup/.authorized_keys"

# Challenge 9
test_and_capture_flag 9 "grep resolv.conf" \
    "grep -o 'CTF{[^}]*}' /etc/resolv.conf"

# Challenge 10 - trigger file creation and check flag file
echo "Testing Challenge 10 (creating trigger file)..."
true > /tmp/.ctf_upload_triggered 2>/dev/null || true
TRIGGER_FILE="/home/ctf_user/ctf_challenges/test_trigger_$$"
touch "$TRIGGER_FILE"
sleep 3
sync
test_and_capture_flag 10 "trigger file creates flag" \
    "cat /tmp/.ctf_upload_triggered 2>/dev/null"
rm -f "$TRIGGER_FILE"

# Challenge 11
test_and_capture_flag 11 "curl localhost:8083" \
    "curl -s --connect-timeout 5 --max-time 10 localhost:8083"

# Challenge 12 - read hex pattern from ping script and decode
echo "Testing Challenge 12 (hex decode ping pattern)..."
HEX_PATTERN=$(grep -o "ping -p [a-f0-9]*" /usr/local/bin/ping_message.sh | awk '{print $3}')
if [ -n "$HEX_PATTERN" ]; then
    CAPTURED_FLAG_12=$(echo "$HEX_PATTERN" | xxd -r -p)
    if echo "$CAPTURED_FLAG_12" | grep -q "CTF{"; then
        pass "Challenge 12 solution: hex decode ping pattern returns flag"
    else
        fail "Challenge 12 solution: hex decode failed (got: $CAPTURED_FLAG_12)"
        CAPTURED_FLAG_12=""
    fi
else
    fail "Challenge 12 solution: could not find hex pattern in ping script"
    CAPTURED_FLAG_12=""
fi

# Challenge 13
test_and_capture_flag 13 "grep cron file" \
    "grep -o 'CTF{[^}]*}' /etc/cron.d/ctf_secret_task"

# Challenge 14
test_and_capture_flag 14 "read process environ" \
    "cat /proc/\$(pgrep -f ctf_secret_process)/environ | tr '\0' '\n' | grep -o 'CTF{[^}]*}'"

# Challenge 15 - extract nested archives
echo "Testing Challenge 15 (extracting archives)..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
tar -xzf /home/ctf_user/ctf_challenges/mystery_archive.tar.gz
tar -xzf middle.tar.gz
tar -xzf inner.tar.gz
test_and_capture_flag 15 "nested archive extraction" \
    "cat flag.txt"
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Challenge 16
test_and_capture_flag 16 "follow symlinks" \
    "cat \$(readlink -f /home/ctf_user/ctf_challenges/follow_me)"

# Challenge 17
test_and_capture_flag 17 "grep old_admin history" \
    "grep -o 'CTF{[^}]*}' /home/old_admin/.bash_history"

# Challenge 18 - mount disk image and read flag
echo "Testing Challenge 18 (mounting disk image)..."
echo 'CTFpassword123!' | sudo -S mkdir -p /mnt/ctf_test_disk 2>/dev/null
echo 'CTFpassword123!' | sudo -S mount -o loop /opt/ctf_disk.img /mnt/ctf_test_disk 2>/dev/null
test_and_capture_flag 18 "mount disk and read flag" \
    "cat /mnt/ctf_test_disk/.flag"
echo 'CTFpassword123!' | sudo -S umount /mnt/ctf_test_disk 2>/dev/null || true

# ============================================================================
section "FLAG VERIFICATION TESTS"
# ============================================================================

echo "Submitting captured flags through verify command..."

# Reset completed challenges for clean test
rm -f ~/.completed_challenges

# Example flag (static)
run_test_output "verify 0 CTF{example}" \
    "verify 0 CTF{example}" "✓"

# Helper to verify captured flag
verify_captured_flag() {
    local num="$1"
    local flag_var="CAPTURED_FLAG_$num"
    local flag="${!flag_var}"
    
    if [ -n "$flag" ]; then
        # Capture output first, then grep (more reliable than piping)
        local output
        output=$(verify "$num" "$flag" 2>&1) || true
        if echo "$output" | grep -qE "(Correct|verified)"; then
            pass "verify $num with captured flag"
        else
            fail "verify $num with captured flag (flag: $flag)"
        fi
    else
        fail "verify $num - no captured flag to submit"
    fi
}

verify_captured_flag 1
verify_captured_flag 2
verify_captured_flag 3
verify_captured_flag 4
verify_captured_flag 5
verify_captured_flag 6
verify_captured_flag 7
verify_captured_flag 8
verify_captured_flag 9
verify_captured_flag 10
verify_captured_flag 11
verify_captured_flag 12
verify_captured_flag 13
verify_captured_flag 14
verify_captured_flag 15
verify_captured_flag 16
verify_captured_flag 17
verify_captured_flag 18

# Verify final progress
run_test_output "verify progress shows 18/18" \
    "verify progress" "18/18"

# ============================================================================
section "TEST SUMMARY"
# ============================================================================

echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $TOTAL"

# Handle reboot test
if [ "$WITH_REBOOT" = true ]; then
    section "REBOOT TEST PREPARATION"
    
    # Save progress count for post-reboot verification
    if [ -f ~/.completed_challenges ]; then
        sort -u ~/.completed_challenges | wc -l > "$PROGRESS_SNAPSHOT"
    fi
    
    # Create marker file
    touch "$REBOOT_MARKER"
    
    echo "Reboot marker created at $REBOOT_MARKER"
    echo "Progress snapshot saved to $PROGRESS_SNAPSHOT"
    echo ""
    echo "Exiting with code 100 to signal reboot request."
    echo "After reboot, re-run this script to verify services and progress persistence."
    exit 100
fi

# Final result
if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi
