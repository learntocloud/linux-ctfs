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
#   ./test_ctf_challenges.sh [--with-reboot|--post-reboot]
#   DEBUG=true ./test_ctf_challenges.sh  # Enable debug tracing
#
# Flags:
#   --with-reboot     After tests pass, signal reboot to verify services persist
#   --post-reboot     Run only the post-reboot verification phase
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

# File paths for reboot test coordination. These must survive a VM reboot.
readonly TEST_STATE_DIR="${HOME}/.linux-ctfs-test"
readonly REBOOT_MARKER="${TEST_STATE_DIR}/.ctf_reboot_test_marker"
readonly PROGRESS_SNAPSHOT="${TEST_STATE_DIR}/.ctf_progress_snapshot"

# =============================================================================
# GLOBAL STATE
# =============================================================================

# Test result counters (mutable)
PASSED=0
FAILED=0

# Parse arguments
WITH_REBOOT=false
POST_REBOOT=false
usage() {
    echo "Usage: $0 [--with-reboot|--post-reboot]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-reboot)
            WITH_REBOOT=true
            ;;
        --post-reboot)
            POST_REBOOT=true
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

if [[ "${WITH_REBOOT}" == true && "${POST_REBOOT}" == true ]]; then
    echo "--with-reboot and --post-reboot cannot be used together."
    usage
    exit 1
fi

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
if [[ "${POST_REBOOT}" == true ]]; then
    _section "POST-REBOOT VERIFICATION"

    if [[ ! -f "${REBOOT_MARKER}" ]]; then
        _fail "Reboot marker not found - reboot verification was not prepared"
        echo ""
        echo "Passed: ${PASSED} | Failed: ${FAILED}"
        exit 1
    fi

    echo "Verifying services survived reboot..."

    for service in ctf-secret-service ctf-monitor-directory ctf-ping-message ctf-secret-process ctf-dns ctf-ssh-key-watch auditd nginx; do
        if systemctl is-active "${service}" &>/dev/null; then
            _pass "${service} is running after reboot"
        else
            _fail "${service} failed to start after reboot - SETUP BUG"
        fi
    done

    if [ -f "$PROGRESS_SNAPSHOT" ]; then
        EXPECTED=$(cat "$PROGRESS_SNAPSHOT")
        ACTUAL=$( { sort -u /var/ctf/completed_challenges 2>/dev/null || true; } | wc -l )
        if [ "$ACTUAL" -ge "$EXPECTED" ]; then
            _pass "Progress persisted after reboot ($ACTUAL checks)"
        else
            _fail "Progress lost after reboot (expected ${EXPECTED}, got ${ACTUAL})"
        fi
    fi

    rm -f "${REBOOT_MARKER}" "${PROGRESS_SNAPSHOT}"
    rmdir "${TEST_STATE_DIR}" 2>/dev/null || true

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

# Timer should not start before first numeric verify command
rm -f /var/ctf/ctf_start_time /var/ctf/ctf_end_time
TIMER_PRESTART_OUT=$(verify time 2>&1) || true
if echo "${TIMER_PRESTART_OUT}" | grep -q "Timer not started"; then
    _pass "verify time shows pre-start message"
else
    _fail "verify time pre-start behavior incorrect"
fi

VERIFY_OUTPUT=$(verify 0 "CTF{example}" 2>&1) || true
if echo "${VERIFY_OUTPUT}" | grep -q "✓"; then
    _pass "verify command accepts example flag"
else
    _fail "verify command broken - SETUP BUG"
    echo "Cannot continue without working verify command"
    exit 1
fi

if echo "${VERIFY_OUTPUT}" | grep -q "1/19"; then
    _pass "verify progress counts the example check"
else
    _fail "verify progress did not show 1/19 after the example check"
fi

if [[ -f /var/ctf/ctf_start_time ]]; then
    _pass "Timer starts after first numeric verify command"
else
    _fail "Timer did not start after first numeric verify command"
fi

# ============================================================================
# SHORTCUT REGRESSION CHECKS
# ============================================================================
# Each check guards against a way to grab a flag without the intended skill.
_section "SHORTCUT REGRESSION CHECKS"

_no_flag() {
    local description="${1}"
    local content="${2}"
    if echo "${content}" | grep -q 'CTF{'; then
        _fail "Shortcut open: ${description}"
    else
        _pass "Shortcut closed: ${description}"
    fi
}

_no_flag "ch8 flag not planted in ~/.ssh" "$(grep -rah 'CTF{' /home/ctf_user/.ssh 2>/dev/null || true)"
_no_flag "ch9 flag not in resolved config" "$(cat /etc/systemd/resolved.conf.d/* 2>/dev/null || true)"
touch /home/ctf_user/ctf_challenges/local_touch_test
LOCAL_IGNORED=false
for _ in {1..10}; do
    grep -q 'ignored local_touch_test' /var/log/monitor_directory.log 2>/dev/null && { LOCAL_IGNORED=true; break; }
    sleep 1
done
rm -f /home/ctf_user/ctf_challenges/local_touch_test
if [[ "${LOCAL_IGNORED}" == true ]]; then
    _pass "Shortcut closed: ch10 local file creation is ignored"
else
    _fail "Shortcut open: ch10 local file creation was not rejected"
fi
_no_flag "ch11 flag not served on port 8083" "$(curl -s --connect-timeout 3 localhost:8083 2>/dev/null || true)"
_no_flag "ch11 flag page not readable by ctf_user" "$(cat /var/www/ctf/index.html 2>/dev/null || true)"
_no_flag "ch12 flag not in ping script or logs" "$(cat /usr/local/bin/ping_message.sh /var/log/ping_message.log 2>/dev/null; grep -o 'PATTERN: 0x[0-9a-f]*' /var/log/ping_message.log 2>/dev/null | cut -c12- | xxd -r -p 2>/dev/null || true)"
_no_flag "ch13 flag not in cron files" "$(cat /etc/cron.d/* /usr/local/bin/ctf_status_report.sh 2>/dev/null || true)"
_no_flag "ch14 flag not exposed by systemctl" "$(systemctl cat ctf-secret-process.service 2>/dev/null; systemctl show ctf-secret-process.service 2>/dev/null || true)"
_no_flag "ch16 cat follow_me does not print the flag" "$(cat /home/ctf_user/ctf_challenges/follow_me 2>/dev/null || true)"
_no_flag "ch17 history unreadable without sudo" "$(cat /home/old_admin/.bash_history 2>/dev/null || true)"
_no_flag "ch18 disk image unreadable without sudo" "$(grep -ao 'CTF{[^}]*}' /opt/ctf_disk.img 2>/dev/null || true)"
if getent hosts ubuntu.com >/dev/null 2>&1; then
    _pass "Normal DNS resolution still works with the ch9 resolver"
else
    _fail "Normal DNS resolution broken by the ch9 resolver - SETUP BUG"
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
        | grep -vE '^(22|53|54|80|443|8083)$' \
        | sort -u); do
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

# Challenge 8: SSH Key Authentication
# Hint: "Create a key pair, ssh-copy-id it, log in with the key, watch the banner"
# deploy_and_test.sh performs the key setup and key login from the local machine
# before this script runs; the login banner should now show the flag.
echo "Challenge 8: SSH Key Authentication"
FLAG_8=$(bash -lc true 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
if [[ -n "${FLAG_8}" ]]; then
    _verify_flag 8 "${FLAG_8}" "Solved challenge 8" "Challenge 8: Found flag but verify rejected it - SETUP BUG"
else
    _fail "Challenge 8: key login did not reveal the flag in the login banner - SETUP BUG"
    FLAGS[8]=""
fi

# Challenge 9: DNS Inspection
# Hint: "resolvectl status shows which server handles which domain; query its TXT record"
echo "Challenge 9: DNS Inspection"
DNS_DOMAIN=$(resolvectl status 2>/dev/null \
    | grep -oE '~[a-z0-9.-]+' \
    | grep -v '^~\.$' \
    | tr -d '~' \
    | head -1) || true
if [[ -n "${DNS_DOMAIN}" ]]; then
    FLAG_9=$(dig +short TXT "${DNS_DOMAIN}" 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
    if [[ -n "${FLAG_9}" ]]; then
        _verify_flag 9 "${FLAG_9}" "Solved challenge 9" "Challenge 9: Found flag but verify rejected it - SETUP BUG"
    else
        _fail "Challenge 9: TXT lookup for ${DNS_DOMAIN} returned no flag - SETUP BUG"
        FLAGS[9]=""
    fi
else
    _fail "Challenge 9: No routing domain found in resolvectl status - SETUP BUG"
    FLAGS[9]=""
fi

# Challenge 10: Remote Upload
# Hint: "Run scp from your own computer into ~/ctf_challenges/"
# deploy_and_test.sh uploads a file with scp from the local machine before this
# script runs, so the login banner should now show the flag.
echo "Challenge 10: Remote Upload"
if ! systemctl is-active ctf-monitor-directory.service &>/dev/null; then
    _fail "Challenge 10: Monitor service not running - SETUP BUG"
    FLAGS[10]=""
else
    FLAG_10=""
    for _ in {1..10}; do
        FLAG_10=$(bash -lc true 2>/dev/null | grep 'Challenge 10' | grep -ao 'CTF{[^}]*}' | head -1) || true
        [[ -n "${FLAG_10}" ]] && break
        sleep 2
    done
    rm -f /home/ctf_user/ctf_challenges/scp_upload_test

    if [[ -n "${FLAG_10}" ]]; then
        _verify_flag 10 "${FLAG_10}" "Solved challenge 10" "Challenge 10: Found flag but verify rejected it - SETUP BUG"
    else
        _fail "Challenge 10: scp upload did not trigger the flag - SETUP BUG"
        FLAGS[10]=""
    fi
fi

# Challenge 11: Web Configuration
# Hint: "Check nginx's port with ss, move it to the standard port, reload"
echo "Challenge 11: Web Configuration"
NGINX_SITE=$(grep -RlE 'listen\s+[0-9]+' /etc/nginx/sites-enabled/ 2>/dev/null | head -1) || true
if [[ -n "${NGINX_SITE}" ]]; then
    NGINX_SITE=$(readlink -f "${NGINX_SITE}")
    echo 'CTFpassword123!' | sudo -S sed -i -E 's/listen(\s+)(\[::\]:)?8083/listen\1\280/' "${NGINX_SITE}" 2>/dev/null
    echo 'CTFpassword123!' | sudo -S systemctl reload nginx 2>/dev/null || true
    sleep 2
    FLAG_11=$(curl -s "localhost:80" 2>/dev/null \
        | grep -ao 'CTF{[^}]*}' \
        | head -1) || true
    if [[ -n "${FLAG_11}" ]]; then
        _verify_flag 11 "${FLAG_11}"
    else
        _fail "Challenge 11: nginx on port 80 did not serve the flag"
        FLAGS[11]=""
    fi
else
    _fail "Challenge 11: Could not find nginx site config"
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
# Hint: "Check /etc/cron.d/; read the script a job runs and work out when its output exists"
echo "Challenge 13: Cron Job Hunter"
FLAG_13=""
CRON_SCRIPT=$(grep -hvE '^\s*(#|$)' /etc/cron.d/* 2>/dev/null \
    | awk 'NF >= 7 {print $7}' \
    | grep '^/usr/local/' \
    | head -1) || true
if [[ -n "${CRON_SCRIPT}" && -r "${CRON_SCRIPT}" ]]; then
    REPORT=$(grep -oP '^REPORT=\K\S+' "${CRON_SCRIPT}" | head -1) || true
    for _ in {1..40}; do
        FLAG_13=$(grep -ao 'CTF{[^}]*}' "${REPORT}" 2>/dev/null | head -1) || true
        [[ -n "${FLAG_13}" ]] && break
        sleep 2
    done
fi
if [[ -n "${FLAG_13}" ]]; then
    _verify_flag 13 "${FLAG_13}"
else
    _fail "Challenge 13: Could not catch the cron job's output"
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
# Hint: "Use 'readlink -f' to find the final target; the path can matter"
echo "Challenge 16: Symbolic Sleuth"
FLAG_16=""
while IFS= read -r -d '' link; do
    FLAG_16=$(readlink -f "${link}" 2>/dev/null | grep -ao 'CTF{[^}]*}' | head -1) || true
    [[ -n "${FLAG_16}" ]] && break
done < <(find /home/ctf_user/ctf_challenges -type l -print0 2>/dev/null)
if [[ -n "${FLAG_16}" ]]; then
    _verify_flag 16 "${FLAG_16}"
else
    _fail "Challenge 16: Could not find flag via symlinks"
    FLAGS[16]=""
fi

# Challenge 17: History Mystery
# Hint: "Other users' history files are private, but you have sudo"
echo "Challenge 17: History Mystery"
FLAG_17=""
for home in /home/*; do
    user=$(basename "${home}")
    [[ "${user}" == "ctf_user" ]] && continue
    [[ -e "${home}/.bash_history" ]] || continue
    FLAG_17=$(echo 'CTFpassword123!' | sudo -S cat "${home}/.bash_history" 2>/dev/null \
        | grep -ao 'CTF{[^}]*}' \
        | head -1) || true
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

SUFFIXES=$(for n in "${!FLAGS[@]}"; do
    [[ "${n}" == "0" || -z "${FLAGS[${n}]}" ]] && continue
    echo "${FLAGS[${n}]}" | grep -oE '_[0-9a-f]+\}$'
done | sort)
if [[ -n "${SUFFIXES}" && "$(echo "${SUFFIXES}" | wc -l)" == "$(echo "${SUFFIXES}" | sort -u | wc -l)" ]]; then
    _pass "Every flag has its own random suffix"
else
    _fail "Flags share suffixes - one flag predicts the others"
fi

# ============================================================================
# VERIFICATION TOKEN TEST
# ============================================================================
_section "VERIFICATION TOKEN TEST"

PROGRESS=$(verify progress 2>&1)
if echo "${PROGRESS}" | grep -q "19/19"; then
    _pass "All 19 progress checks completed"
else
    _fail "Not all progress checks completed: ${PROGRESS}"
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

FIRST_TIME_OUT=$(verify time 2>&1) || true
sleep 2
SECOND_TIME_OUT=$(verify time 2>&1) || true
if [[ "${FIRST_TIME_OUT}" == "${SECOND_TIME_OUT}" ]]; then
    _pass "verify time is frozen after first successful export"
else
    _fail "verify time changed after export (freeze failed)"
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
    mkdir -p "${TEST_STATE_DIR}"
    sort -u /var/ctf/completed_challenges 2>/dev/null | wc -l > "$PROGRESS_SNAPSHOT"
    touch "$REBOOT_MARKER"
    echo "Reboot marker created. After reboot, re-run with --post-reboot to verify services."
    exit 100
fi

if [[ ${FAILED} -eq 0 ]]; then
    echo -e "${GREEN}All tests passed! Students can complete this CTF.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Students may be blocked.${NC}"
    exit 1
fi
