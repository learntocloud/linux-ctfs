#!/usr/bin/env bash
# shellcheck shell=bash
#
# CTF Challenge Test Script
# Runs on the VM to validate all challenges are solvable by students
#
# This script simulates a real user journey - discovering and solving each
# challenge using only the hints provided. If these tests pass, students
# can complete the CTF.
#
# Usage:
#   ./test_ctf_challenges.sh [--with-reboot]
#   DEBUG=true ./test_ctf_challenges.sh  # Enable debug tracing
#
# Flags:
#   --with-reboot     After tests pass, signal reboot to verify services persist
#
# Exit codes:
#   0   - All tests passed
#   1   - One or more tests failed
#   100 - Reboot requested (only with --with-reboot flag)
#

set -o errexit
set -o pipefail
set -o nounset

# Enable debug tracing if DEBUG=true
[[ "${DEBUG:-}" == 'true' ]] && set -o xtrace

# Ensure verify command is available
# It's installed in /usr/local/bin by ctf_setup.sh
if ! command -v verify &>/dev/null; then
    export PATH="/usr/local/bin:$PATH"
fi

# =============================================================================
# CONSTANTS
# =============================================================================

# Terminal colors for output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'  # No Color

# File paths for reboot test coordination
readonly REBOOT_MARKER="/tmp/.ctf_reboot_test_marker"
readonly PROGRESS_SNAPSHOT="/tmp/.ctf_progress_snapshot"

# =============================================================================
# GLOBAL STATE
# =============================================================================

# Test result counters (mutable)
PASSED=0
FAILED=0

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

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Log a passing test result and increment counter
# Arguments:
#   $1 - Message describing what passed
_pass() {
    local message="${1}"
    echo -e "${GREEN}✓ PASS${NC}: ${message}"
    ((PASSED++)) || true
}

# Log a failing test result and increment counter
# Arguments:
#   $1 - Message describing what failed
_fail() {
    local message="${1}"
    echo -e "${RED}✗ FAIL${NC}: ${message}"
    ((FAILED++)) || true
}

# Print a section header for visual separation in output
# Arguments:
#   $1 - Section title to display
_section() {
    local title="${1}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}${title}${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Verify a flag with the verify command and record result
# Arguments:
#   $1 - Challenge number
#   $2 - Flag value to verify
#   $3 - Success message (optional, defaults to "Solved challenge N")
#   $4 - Failure message (optional, defaults to "Found flag but verify rejected it")
# Returns:
#   0 if flag was verified successfully, 1 otherwise
_verify_flag() {
    local challenge_num="${1}"
    local flag_value="${2}"
    local success_msg="${3:-Solved challenge ${challenge_num}}"
    local fail_msg="${4:-Challenge ${challenge_num}: Found flag but verify rejected it}"
    local verify_out

    verify_out=$(verify "${challenge_num}" "${flag_value}" 2>&1) || true
    if echo "${verify_out}" | grep -qE "(Correct|verified)"; then
        _pass "${success_msg}"
        FLAGS[${challenge_num}]="${flag_value}"
        return 0
    else
        _fail "${fail_msg}"
        FLAGS[${challenge_num}]=""
        return 1
    fi
}

# ============================================================================
# POST-REBOOT VERIFICATION
# ============================================================================
if [[ -f "${REBOOT_MARKER}" ]]; then
    _section "POST-REBOOT VERIFICATION"
    
    echo "Verifying services survived reboot..."
    
    for service in ctf-secret-service ctf-monitor-directory ctf-ping-message ctf-secret-process nginx; do
        if systemctl is-active "${service}" &>/dev/null; then
            _pass "${service} is running after reboot"
        else
            _fail "${service} failed to start after reboot - SETUP BUG"
        fi
    done
    
    if [ -f "$PROGRESS_SNAPSHOT" ]; then
        EXPECTED=$(cat "$PROGRESS_SNAPSHOT")
        ACTUAL=$(sort -u /var/ctf/completed_challenges 2>/dev/null | wc -l)
        if [ "$ACTUAL" -ge "$EXPECTED" ]; then
            pass "Progress persisted after reboot ($ACTUAL challenges)"
        else
            _fail "Progress lost after reboot (expected ${EXPECTED}, got ${ACTUAL})"
        fi
    fi
    
    rm -f "${REBOOT_MARKER}" "${PROGRESS_SNAPSHOT}"
    
    echo ""
    echo "Passed: ${PASSED} | Failed: ${FAILED}"
    [[ ${FAILED} -eq 0 ]] && exit 0 || exit 1
fi

# ============================================================================
# VERIFY COMMAND SANITY CHECK
# ============================================================================
_section "VERIFY COMMAND SANITY CHECK"

# Quick check that the verify command works at all
if ! command -v verify &>/dev/null; then
    _fail "verify command not found in PATH"
    echo "PATH: ${PATH}"
    echo "Looking for verify: $(which verify 2>&1 || echo 'not found')"
    echo "Checking /usr/local/bin: $(ls -la /usr/local/bin/verify 2>&1 || echo 'not found')"
    exit 1
fi

VERIFY_OUTPUT=$(verify 0 "CTF{example}" 2>&1) || true
if echo "${VERIFY_OUTPUT}" | grep -q "✓"; then
    _pass "verify command accepts example flag"
else
    _fail "verify command broken - SETUP BUG"
    echo "Cannot continue without working verify command"
    exit 1
fi

# ============================================================================
# CHALLENGE DISCOVERY AND SOLVING
# ============================================================================
_section "SOLVING ALL CHALLENGES"

echo "Simulating real student journey using hints to discover and solve each challenge..."
echo ""

# Store discovered flags
declare -A FLAGS

# Challenge 1: Hidden File Discovery
# Hint: "Hidden files in Linux start with a dot. Try 'ls -la'"
echo "Challenge 1: Hidden File Discovery"
HIDDEN_FILE=$(ls -la /home/ctf_user/ctf_challenges/ 2>/dev/null \
    | awk '/^-.*\./ {print $NF}' \
    | grep '^\.' \
    | head -1) || true
if [[ -n "${HIDDEN_FILE}" ]]; then
    FLAG_1=$(cat "/home/ctf_user/ctf_challenges/${HIDDEN_FILE}" 2>/dev/null \
        | grep -ao 'CTF{[^}]*}' \
        | head -1) || true
    if [[ -n "${FLAG_1}" ]]; then
        _verify_flag 1 "${FLAG_1}"
    else
        _fail "Challenge 1: Found file but no CTF flag in it"
        FLAGS[1]=""
    fi
else
    _fail "Challenge 1: No hidden files found with ls -la"
    FLAGS[1]=""
fi

# Challenge 2: Basic File Search
# Hint: "Use find to search for files. Try: find ~ -name '*.txt'"
echo "Challenge 2: Basic File Search"
TXT_FILE=$(find /home/ctf_user/documents -name '*.txt' -type f 2>/dev/null | head -1) || true
if [[ -n "${TXT_FILE}" ]]; then
    FLAG_2=$(cat "${TXT_FILE}" 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
    if [[ -n "${FLAG_2}" ]]; then
        _verify_flag 2 "${FLAG_2}"
    else
        _fail "Challenge 2: Found file but no CTF flag in it"
        FLAGS[2]=""
    fi
else
    _fail "Challenge 2: No .txt files found in documents"
    FLAGS[2]=""
fi

# Challenge 3: Log Analysis
# Hint: "Large log files can hide secrets. Check /var/log and use 'tail'"
echo "Challenge 3: Log Analysis"
LARGE_LOG=$(find /var/log -type f -size +100M 2>/dev/null | head -1) || true
if [[ -n "${LARGE_LOG}" ]]; then
    FLAG_3=$(tail -1 "${LARGE_LOG}" 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
    if [[ -n "${FLAG_3}" ]]; then
        _verify_flag 3 "${FLAG_3}"
    else
        _fail "Challenge 3: Found log but no CTF flag in it"
        FLAGS[3]=""
    fi
else
    _fail "Challenge 3: No large log files found"
    FLAGS[3]=""
fi

# Challenge 4: User Investigation
# Hint: "Investigate other users. Check /etc/passwd or use 'getent passwd'"
echo "Challenge 4: User Investigation"
FLAG_4=""
for user in $(getent passwd | awk -F: '$3 >= 1000 && $1 != "ctf_user" && $1 != "nobody" {print $1}'); do
    if [[ -r "/home/${user}/.profile" ]]; then
        FLAG_4=$(grep -ao 'CTF{[^}]*}' "/home/${user}/.profile" 2>/dev/null | head -1) || true
        [[ -n "${FLAG_4}" ]] && break
    fi
done
if [[ -n "${FLAG_4}" ]]; then
    _verify_flag 4 "${FLAG_4}"
else
    _fail "Challenge 4: Could not find flag in user profiles"
    FLAGS[4]=""
fi

# Challenge 5: Permission Analysis
# Hint: "Look for files with unusual permissions. Try: find / -perm 777"
echo "Challenge 5: Permission Analysis"
FLAG_5=""
for path in /opt /etc /var; do
    PERM_FILE=$(find "${path}" -type f -perm 777 2>/dev/null | head -1) || true
    if [[ -n "${PERM_FILE}" ]]; then
        FLAG_5=$(cat "${PERM_FILE}" 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
        [[ -n "${FLAG_5}" ]] && break
    fi
done
if [[ -n "${FLAG_5}" ]]; then
    _verify_flag 5 "${FLAG_5}"
else
    _fail "Challenge 5: Could not find flag in 777 permission files"
    FLAGS[5]=""
fi

# Challenge 6: Service Discovery
# Hint: "What services are running? Use 'ss -tulpn' to find listening ports"
echo "Challenge 6: Service Discovery"
FLAG_6=""
for port in $(ss -tulpn 2>/dev/null \
        | awk '/LISTEN/ {split($5,a,":"); print a[length(a)]}' \
        | grep -vE '^(22|80|443|8083)$' \
        | head -3); do
    FLAG_6=$(curl -s --connect-timeout 3 "localhost:${port}" 2>/dev/null \
        | grep -ao 'CTF{[^}]*}' \
        | head -1) || true
    [[ -n "${FLAG_6}" ]] && break
done
if [[ -n "${FLAG_6}" ]]; then
    _verify_flag 6 "${FLAG_6}"
else
    _fail "Challenge 6: Could not find flag from listening services"
    FLAGS[6]=""
fi

# Challenge 7: Encoding Challenge
# Hint: "The flag is encoded. Use 'base64 -d' to decode"
echo "Challenge 7: Encoding Challenge"
ENCODED_FILE=$(find /home/ctf_user/ctf_challenges -name '*.txt' -type f 2>/dev/null | head -1) || true
if [[ -n "${ENCODED_FILE}" ]]; then
    FLAG_7=$(cat "${ENCODED_FILE}" 2>/dev/null \
        | base64 -d 2>/dev/null \
        | base64 -d 2>/dev/null \
        | grep -ao 'CTF{[^}]*}' \
        | head -1) || true
    if [[ -n "${FLAG_7}" ]]; then
        _verify_flag 7 "${FLAG_7}"
    else
        _fail "Challenge 7: Could not decode flag from file"
        FLAGS[7]=""
    fi
else
    _fail "Challenge 7: No encoded file found"
    FLAGS[7]=""
fi

# Challenge 8: SSH Secrets
# Hint: "SSH configurations often hide secrets. Explore ~/.ssh thoroughly"
echo "Challenge 8: SSH Secrets"
FLAG_8=""
while IFS= read -r -d '' f; do
    FLAG_8=$(grep -ao 'CTF{[^}]*}' "${f}" 2>/dev/null | head -1) || true
    [[ -n "${FLAG_8}" ]] && break
done < <(find /home/ctf_user/.ssh -type f -print0 2>/dev/null)
if [[ -n "${FLAG_8}" ]]; then
    _verify_flag 8 "${FLAG_8}"
else
    _fail "Challenge 8: Could not find flag in .ssh directory"
    FLAGS[8]=""
fi

# Challenge 9: DNS Configuration
# Hint: "DNS settings are stored in /etc/resolv.conf"
echo "Challenge 9: DNS Configuration"
if [[ -r /etc/resolv.conf ]]; then
    FLAG_9=$(grep -ao 'CTF{[^}]*}' /etc/resolv.conf 2>/dev/null | head -1) || true
    if [[ -n "${FLAG_9}" ]]; then
        _verify_flag 9 "${FLAG_9}" "Solved challenge 9" "Challenge 9: Found flag but verify rejected it - SETUP BUG"
    else
        _fail "Challenge 9: resolv.conf has no CTF flag - SETUP BUG"
        FLAGS[9]=""
    fi
else
    _fail "Challenge 9: /etc/resolv.conf not readable - SETUP BUG"
    FLAGS[9]=""
fi

# Challenge 10: File Monitoring
# Hint: "Try creating a file in ctf_challenges"
echo "Challenge 10: File Monitoring"
if ! systemctl is-active ctf-monitor-directory.service &>/dev/null; then
    _fail "Challenge 10: Monitor service not running - SETUP BUG"
    FLAGS[10]=""
else
    # Wait for inotifywait process to actually be running (service starts but has internal delay)
    echo "  Waiting for inotifywait to be ready..."
    for _ in {1..15}; do
        pgrep -f "inotifywait.*ctf_challenges" &>/dev/null && break
        sleep 2
    done
    
    true > /tmp/.ctf_upload_triggered 2>/dev/null || true
    TRIGGER="/home/ctf_user/ctf_challenges/test_$$"
    touch "${TRIGGER}"
    sleep 3
    
    FLAG_10=""
    for _ in {1..10}; do
        FLAG_10=$(grep -ao 'CTF{[^}]*}' /tmp/.ctf_upload_triggered 2>/dev/null | head -1) || true
        [[ -n "${FLAG_10}" ]] && break
        sleep 2
    done
    rm -f "${TRIGGER}"
    
    if [[ -n "${FLAG_10}" ]]; then
        _verify_flag 10 "${FLAG_10}" "Solved challenge 10" "Challenge 10: Found flag but verify rejected it - SETUP BUG"
    else
        _fail "Challenge 10: File monitoring did not trigger - SETUP BUG"
        FLAGS[10]=""
    fi
fi

# Challenge 11: Web Configuration
# Hint: "Check what ports nginx is listening on"
echo "Challenge 11: Web Configuration"
NGINX_PORT=$(grep -r 'listen' /etc/nginx/ 2>/dev/null \
    | grep -oP 'listen\s+\K[0-9]+' \
    | grep -v '^80$' \
    | head -1) || true
if [[ -n "${NGINX_PORT}" ]]; then
    FLAG_11=$(curl -s "localhost:${NGINX_PORT}" 2>/dev/null \
        | grep -ao 'CTF{[^}]*}' \
        | head -1) || true
    if [[ -n "${FLAG_11}" ]]; then
        _verify_flag 11 "${FLAG_11}"
    else
        _fail "Challenge 11: Could not get flag from nginx"
        FLAGS[11]=""
    fi
else
    _fail "Challenge 11: Could not find nginx non-standard port"
    FLAGS[11]=""
fi

# Challenge 12: Network Traffic Analysis
# Hint: "Look at ping patterns with tcpdump"
echo "Challenge 12: Network Traffic Analysis"
TCPDUMP_OUT=$(echo 'CTFpassword123!' \
    | sudo -S timeout 10 tcpdump -i lo -c 4 -X icmp 2>/dev/null) || true
if [[ -n "${TCPDUMP_OUT}" ]]; then
    HEX=$(echo "${TCPDUMP_OUT}" \
        | grep -E '^\s+0x' \
        | awk '{print $2$3$4$5$6$7$8$9}' \
        | tr -d '\n')
    FLAG_12=$(echo "${HEX}" | xxd -r -p 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
    
    if [[ -n "${FLAG_12}" ]]; then
        _verify_flag 12 "${FLAG_12}"
    else
        _fail "Challenge 12: Could not extract flag from ping traffic"
        FLAGS[12]=""
    fi
else
    _fail "Challenge 12: tcpdump capture failed"
    FLAGS[12]=""
fi

# Challenge 13: Cron Job Hunter
# Hint: "Check /etc/cron.d/, /etc/crontab, and user crontabs"
echo "Challenge 13: Cron Job Hunter"
FLAG_13=""
for dir in /etc/cron.d /etc/cron.daily /etc/cron.hourly; do
    [[ -d "${dir}" ]] || continue
    FLAG_13=$(grep -rh 'CTF{' "${dir}" 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
    [[ -n "${FLAG_13}" ]] && break
done
if [[ -n "${FLAG_13}" ]]; then
    _verify_flag 13 "${FLAG_13}"
else
    _fail "Challenge 13: Could not find flag in cron directories"
    FLAGS[13]=""
fi

# Challenge 14: Process Environment
# Hint: "Process info lives in /proc. Check /proc/PID/environ"
echo "Challenge 14: Process Environment"
FLAG_14=""
for pid in $(pgrep -u ctf_user 2>/dev/null); do
    [[ -r "/proc/${pid}/environ" ]] || continue
    FLAG_14=$(tr '\0' '\n' < "/proc/${pid}/environ" 2>/dev/null | grep -ao 'CTF{[^}]*}') || true
    [[ -n "${FLAG_14}" ]] && break
done
if [[ -n "${FLAG_14}" ]]; then
    _verify_flag 14 "${FLAG_14}"
else
    _fail "Challenge 14: Could not find flag in process environments"
    FLAGS[14]=""
fi

# Challenge 15: Archive Archaeologist
# Hint: "Archives can be nested. Use 'tar -xzf' to extract layers"
echo "Challenge 15: Archive Archaeologist"
ARCHIVE=$(find /home/ctf_user/ctf_challenges -name '*.tar.gz' 2>/dev/null | head -1) || true
if [[ -n "${ARCHIVE}" ]]; then
    TMPDIR=$(mktemp -d)
    cd "${TMPDIR}"
    tar -xzf "${ARCHIVE}" 2>/dev/null || true
    for _ in {1..5}; do
        INNER=$(find . -maxdepth 1 -name '*.tar.gz' 2>/dev/null | head -1) || true
        [[ -z "${INNER}" ]] && break
        tar -xzf "${INNER}" 2>/dev/null || true
        rm -f "${INNER}"
    done
    FLAG_15=$(grep -rh 'CTF{' . 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
    cd - >/dev/null
    rm -rf "${TMPDIR}"
    
    if [[ -n "${FLAG_15}" ]]; then
        _verify_flag 15 "${FLAG_15}"
    else
        _fail "Challenge 15: Could not find flag in nested archives"
        FLAGS[15]=""
    fi
else
    _fail "Challenge 15: No archive found"
    FLAGS[15]=""
fi

# Challenge 16: Symbolic Sleuth
# Hint: "Use 'readlink -f' to find the final target"
echo "Challenge 16: Symbolic Sleuth"
FLAG_16=""
while IFS= read -r -d '' link; do
    TARGET=$(readlink -f "${link}" 2>/dev/null) || true
    [[ -r "${TARGET}" ]] || continue
    FLAG_16=$(grep -ao 'CTF{[^}]*}' "${TARGET}" 2>/dev/null | head -1) || true
    [[ -n "${FLAG_16}" ]] && break
done < <(find /home/ctf_user/ctf_challenges -type l -print0 2>/dev/null)
if [[ -n "${FLAG_16}" ]]; then
    _verify_flag 16 "${FLAG_16}"
else
    _fail "Challenge 16: Could not find flag via symlinks"
    FLAGS[16]=""
fi

# Challenge 17: History Mystery
# Hint: "Bash stores history in ~/.bash_history. Other users may have history too"
echo "Challenge 17: History Mystery"
FLAG_17=""
for home in /home/*; do
    user=$(basename "${home}")
    [[ "${user}" == "ctf_user" ]] && continue
    [[ -r "${home}/.bash_history" ]] || continue
    FLAG_17=$(grep -ao 'CTF{[^}]*}' "${home}/.bash_history" 2>/dev/null | head -1) || true
    [[ -n "${FLAG_17}" ]] && break
done
if [[ -n "${FLAG_17}" ]]; then
    _verify_flag 17 "${FLAG_17}"
else
    _fail "Challenge 17: Could not find flag in user histories"
    FLAGS[17]=""
fi

# Challenge 18: Disk Detective
# Hint: "Try mounting disk images with 'sudo mount -o loop'"
echo "Challenge 18: Disk Detective"
DISK_IMG=$(find /opt /home -name '*.img' -type f 2>/dev/null | head -1) || true
if [[ -n "${DISK_IMG}" ]]; then
    MNTDIR=$(mktemp -d)
    echo 'CTFpassword123!' | sudo -S mount -o loop "${DISK_IMG}" "${MNTDIR}" 2>/dev/null
    FLAG_18=$(find "${MNTDIR}" -type f -print0 2>/dev/null \
        | xargs -0 grep -ah 'CTF{' 2>/dev/null \
        | grep -ao 'CTF{[^}]*}' \
        | head -1) || true
    echo 'CTFpassword123!' | sudo -S umount "${MNTDIR}" 2>/dev/null || true
    rmdir "${MNTDIR}" 2>/dev/null || true
    
    if [[ -n "${FLAG_18}" ]]; then
        _verify_flag 18 "${FLAG_18}"
    else
        _fail "Challenge 18: Could not find flag in disk image"
        FLAGS[18]=""
    fi
else
    _fail "Challenge 18: No disk image found"
    FLAGS[18]=""
fi

# ============================================================================
# VERIFICATION TOKEN TEST
# ============================================================================
_section "VERIFICATION TOKEN TEST"

PROGRESS=$(verify progress 2>&1)
if echo "${PROGRESS}" | grep -q "18/18"; then
    _pass "All 18 challenges completed"
else
    _fail "Not all challenges completed: ${PROGRESS}"
fi

EXPORT_OUT=$(verify export testuser 2>&1) || true

if echo "${EXPORT_OUT}" | grep -q "COMPLETION CERTIFICATE"; then
    _pass "Export generates certificate"
else
    _fail "Export missing certificate"
fi

if echo "${EXPORT_OUT}" | grep -q "BEGIN L2C CTF TOKEN"; then
    _pass "Export generates token"
    
    TOKEN=$(echo "${EXPORT_OUT}" \
        | sed -n '/BEGIN L2C CTF TOKEN/,/END L2C CTF TOKEN/p' \
        | grep -v 'L2C CTF TOKEN' \
        | tr -d '\n ')
    DECODED=$(echo "${TOKEN}" | base64 -d 2>/dev/null) || true
    
    if echo "${DECODED}" | grep -q '"github_username":"testuser"'; then
        _pass "Token contains correct username"
    else
        _fail "Token has wrong username"
    fi
    
    if echo "${DECODED}" | grep -q '"challenges":18'; then
        _pass "Token shows 18 challenges"
    else
        _fail "Token has wrong challenge count"
    fi
else
    _fail "Export missing token"
fi

# ============================================================================
# SUMMARY
# ============================================================================
_section "SUMMARY"

echo "Passed: ${PASSED}"
echo "Failed: ${FAILED}"
echo "Flags captured: ${#FLAGS[@]}"
echo ""

if [ "$WITH_REBOOT" = true ] && [ $FAILED -eq 0 ]; then
    sort -u /var/ctf/completed_challenges 2>/dev/null | wc -l > "$PROGRESS_SNAPSHOT"
    touch "$REBOOT_MARKER"
    echo "Reboot marker created. Re-run after reboot to verify services."
    exit 100
fi

if [[ ${FAILED} -eq 0 ]]; then
    echo -e "${GREEN}All tests passed! Students can complete this CTF.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Students may be blocked.${NC}"
    exit 1
fi
