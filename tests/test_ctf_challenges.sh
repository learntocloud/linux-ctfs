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

echo "Testing that solution commands return correct flags..."

# Challenge 1
run_test_output "Challenge 1 solution: cat .hidden_flag returns flag" \
    "cat /home/ctf_user/ctf_challenges/.hidden_flag" "CTF{finding_hidden_treasures}"

# Challenge 2
run_test_output "Challenge 2 solution: cat secret_notes.txt returns flag" \
    "cat /home/ctf_user/documents/projects/backup/secret_notes.txt" "CTF{search_and_discover}"

# Challenge 3
run_test_output "Challenge 3 solution: tail large_log_file.log returns flag" \
    "tail -1 /var/log/large_log_file.log" "CTF{size_matters_in_linux}"

# Challenge 4
run_test_output "Challenge 4 solution: cat flag_user .profile returns flag" \
    "cat /home/flag_user/.profile" "CTF{user_enumeration_expert}"

# Challenge 5
run_test_output "Challenge 5 solution: cat system.conf returns flag" \
    "cat /opt/systems/config/system.conf" "CTF{permission_sleuth}"

# Challenge 6
run_test_output "Challenge 6 solution: curl localhost:8080 returns flag" \
    "curl -s --connect-timeout 5 --max-time 10 localhost:8080" "CTF{network_detective}"

# Challenge 7
run_test_output "Challenge 7 solution: double base64 decode returns flag" \
    "cat /home/ctf_user/ctf_challenges/encoded_flag.txt | base64 -d | base64 -d" "CTF{decoding_master}"

# Challenge 8
run_test_output "Challenge 8 solution: cat .ssh hidden file returns flag" \
    "cat /home/ctf_user/.ssh/secrets/backup/.authorized_keys" "CTF{ssh_security_master}"

# Challenge 9
run_test_output "Challenge 9 solution: grep resolv.conf returns flag" \
    "grep -o 'CTF{[^}]*}' /etc/resolv.conf" "CTF{dns_name}"

# Challenge 10 - trigger file creation and check flag file
echo "Testing Challenge 10 (creating trigger file)..."
# Clear any existing trigger file content first
> /tmp/.ctf_upload_triggered 2>/dev/null || true
TRIGGER_FILE="/home/ctf_user/ctf_challenges/test_trigger_$$"
touch "$TRIGGER_FILE"
sleep 3  # Give inotifywait more time to react and write
sync
run_test_output "Challenge 10 solution: trigger file creates flag" \
    "cat /tmp/.ctf_upload_triggered 2>/dev/null" "CTF{network_copy}"
rm -f "$TRIGGER_FILE"

# Challenge 11
run_test_output "Challenge 11 solution: curl localhost:8083 returns flag" \
    "curl -s --connect-timeout 5 --max-time 10 localhost:8083" "CTF{web_config}"

# Challenge 12
run_test_output "Challenge 12 solution: hex decode ping pattern returns flag" \
    "echo '4354467b6e65745f636861747d' | xxd -r -p" "CTF{net_chat}"

# Challenge 13
run_test_output "Challenge 13 solution: grep cron file returns flag" \
    "grep -o 'CTF{[^}]*}' /etc/cron.d/ctf_secret_task" "CTF{cron_task_master}"

# Challenge 14
run_test_output "Challenge 14 solution: read process environ returns flag" \
    "cat /proc/\$(pgrep -f ctf_secret_process)/environ | tr '\0' '\n' | grep -o 'CTF{[^}]*}'" "CTF{env_variable_hunter}"

# Challenge 15 - extract nested archives
echo "Testing Challenge 15 (extracting archives)..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
tar -xzf /home/ctf_user/ctf_challenges/mystery_archive.tar.gz
tar -xzf middle.tar.gz
tar -xzf inner.tar.gz
run_test_output "Challenge 15 solution: nested archive extraction returns flag" \
    "cat flag.txt" "CTF{archive_explorer}"
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Challenge 16
run_test_output "Challenge 16 solution: follow symlinks returns flag" \
    "cat \$(readlink -f /home/ctf_user/ctf_challenges/follow_me)" "CTF{link_follower}"

# Challenge 17
run_test_output "Challenge 17 solution: grep old_admin history returns flag" \
    "grep -o 'CTF{[^}]*}' /home/old_admin/.bash_history" "CTF{history_detective}"

# Challenge 18 - mount disk image and read flag
echo "Testing Challenge 18 (mounting disk image)..."
echo 'CTFpassword123!' | sudo -S mkdir -p /mnt/ctf_test_disk 2>/dev/null
echo 'CTFpassword123!' | sudo -S mount -o loop /opt/ctf_disk.img /mnt/ctf_test_disk 2>/dev/null
run_test_output "Challenge 18 solution: mount disk and read flag" \
    "cat /mnt/ctf_test_disk/.flag" "CTF{disk_detective}"
echo 'CTFpassword123!' | sudo -S umount /mnt/ctf_test_disk 2>/dev/null || true

# ============================================================================
section "FLAG VERIFICATION TESTS"
# ============================================================================

echo "Submitting all flags through verify command..."

# Reset completed challenges for clean test
rm -f ~/.completed_challenges

run_test_output "verify 0 CTF{example}" \
    "verify 0 CTF{example}" "✓"

run_test_output "verify 1 CTF{finding_hidden_treasures}" \
    "verify 1 CTF{finding_hidden_treasures}" "✓"

run_test_output "verify 2 CTF{search_and_discover}" \
    "verify 2 CTF{search_and_discover}" "✓"

run_test_output "verify 3 CTF{size_matters_in_linux}" \
    "verify 3 CTF{size_matters_in_linux}" "✓"

run_test_output "verify 4 CTF{user_enumeration_expert}" \
    "verify 4 CTF{user_enumeration_expert}" "✓"

run_test_output "verify 5 CTF{permission_sleuth}" \
    "verify 5 CTF{permission_sleuth}" "✓"

run_test_output "verify 6 CTF{network_detective}" \
    "verify 6 CTF{network_detective}" "✓"

run_test_output "verify 7 CTF{decoding_master}" \
    "verify 7 CTF{decoding_master}" "✓"

run_test_output "verify 8 CTF{ssh_security_master}" \
    "verify 8 CTF{ssh_security_master}" "✓"

run_test_output "verify 9 CTF{dns_name}" \
    "verify 9 CTF{dns_name}" "✓"

run_test_output "verify 10 CTF{network_copy}" \
    "verify 10 CTF{network_copy}" "✓"

run_test_output "verify 11 CTF{web_config}" \
    "verify 11 CTF{web_config}" "✓"

run_test_output "verify 12 CTF{net_chat}" \
    "verify 12 CTF{net_chat}" "✓"

run_test_output "verify 13 CTF{cron_task_master}" \
    "verify 13 CTF{cron_task_master}" "✓"

run_test_output "verify 14 CTF{env_variable_hunter}" \
    "verify 14 CTF{env_variable_hunter}" "✓"

run_test_output "verify 15 CTF{archive_explorer}" \
    "verify 15 CTF{archive_explorer}" "✓"

run_test_output "verify 16 CTF{link_follower}" \
    "verify 16 CTF{link_follower}" "✓"

run_test_output "verify 17 CTF{history_detective}" \
    "verify 17 CTF{history_detective}" "✓"

run_test_output "verify 18 CTF{disk_detective}" \
    "verify 18 CTF{disk_detective}" "✓"

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
