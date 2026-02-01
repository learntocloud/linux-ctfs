#!/usr/bin/env bash
# shellcheck shell=bash
#
# CTF Deploy and Test Orchestration Script
# Deploys infrastructure to cloud providers and runs tests
#
# Usage:
#   ./deploy_and_test.sh <aws|azure|gcp|all> [--with-reboot]
#   DEBUG=true ./deploy_and_test.sh azure  # Enable debug tracing
#
# Arguments:
#   aws|azure|gcp|all    Cloud provider(s) to test
#   --with-reboot        After initial tests pass, stop/start the VM and
#                        re-run verification to ensure services survive
#                        reboot and progress persists
#
# Prerequisites:
#   - terraform (>= 1.0)
#   - jq (for AWS terraform config)
#   - sshpass (macOS: brew install hudochenkov/sshpass/sshpass)
#   - aws CLI (for AWS, must be logged in)
#   - az CLI (for Azure, must be logged in)
#   - gcloud CLI (for GCP, must be authenticated)
#
# Examples:
#   ./deploy_and_test.sh aws                    # Test AWS only
#   ./deploy_and_test.sh azure --with-reboot    # Test Azure with reboot
#   ./deploy_and_test.sh all                    # Test all providers
#   ./deploy_and_test.sh all --with-reboot      # Full test suite
#

set -o errexit
set -o pipefail
set -o nounset

# Enable debug tracing if DEBUG=true
[[ "${DEBUG:-}" == 'true' ]] && set -o xtrace

# =============================================================================
# CONSTANTS
# =============================================================================

# Script paths (declare and assign separately to avoid masking return values)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly REPO_ROOT
readonly TEST_SCRIPT="${SCRIPT_DIR}/test_ctf_challenges.sh"

# SSH connection settings
readonly MAX_SSH_ATTEMPTS=30
readonly SSH_RETRY_INTERVAL=10
readonly SSH_USER="ctf_user"
readonly SSH_PASS="CTFpassword123!"
readonly SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# Terminal colors for output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'  # No Color

# =============================================================================
# GLOBAL STATE
# =============================================================================

# Cleanup tracking (mutable - set during test execution)
CURRENT_PROVIDER=""
CLEANUP_ON_EXIT=false

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Log a message with timestamp and color based on level
# Arguments:
#   $1 - Log level (INFO, OK, WARN, ERROR)
#   $@ - Message to log
_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%H:%M:%S')

    case "${level}" in
        INFO)  echo -e "[${timestamp}] ${BLUE}${message}${NC}" ;;
        OK)    echo -e "[${timestamp}] ${GREEN}${message}${NC}" ;;
        WARN)  echo -e "[${timestamp}] ${YELLOW}${message}${NC}" ;;
        ERROR) echo -e "[${timestamp}] ${RED}${message}${NC}" ;;
        *)     echo -e "[${timestamp}] ${level} ${message}" ;;
    esac
}

# Signal handler for cleanup on interrupt (SIGINT/SIGTERM)
# Destroys any in-progress infrastructure before exiting
_cleanup_handler() {
    local exit_code=$?

    if [[ "${CLEANUP_ON_EXIT}" == true ]] && [[ -n "${CURRENT_PROVIDER}" ]]; then
        echo ""
        _log WARN "Caught interrupt - cleaning up ${CURRENT_PROVIDER} infrastructure..."
        _terraform_destroy "${CURRENT_PROVIDER}" || true
    fi
    exit "${exit_code}"
}

trap _cleanup_handler SIGINT SIGTERM

# Execute sshpass command with password passed via file descriptor
# This hides the password from the process list
# Arguments:
#   $@ - Command and arguments to pass to sshpass
_sshpass_cmd() {
    sshpass -f <(printf '%s' "${SSH_PASS}") "$@"
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

WITH_REBOOT=false
PROVIDERS_TO_TEST=()

for arg in "$@"; do
    case "${arg}" in
        aws|azure|gcp)
            PROVIDERS_TO_TEST+=("${arg}")
            ;;
        all)
            PROVIDERS_TO_TEST=("aws" "azure" "gcp")
            ;;
        --with-reboot)
            WITH_REBOOT=true
            ;;
        -h|--help)
            head -32 "$0" | tail -30
            exit 0
            ;;
        *)
            echo "Unknown argument: ${arg}"
            echo "Usage: $0 <aws|azure|gcp|all> [--with-reboot]"
            exit 1
            ;;
    esac
done

if [[ ${#PROVIDERS_TO_TEST[@]} -eq 0 ]]; then
    echo "Usage: $0 <aws|azure|gcp|all> [--with-reboot]"
    exit 1
fi

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

# Verify all required tools are installed and authenticated for a provider
# Arguments:
#   $1 - Cloud provider name (aws, azure, gcp)
_check_prerequisites() {
    local provider="$1"
    local missing=()

    echo -e "${BLUE}Checking prerequisites for ${provider}...${NC}"

    # Check terraform
    if ! command -v terraform &>/dev/null; then
        missing+=("terraform")
    fi

    # Check jq (required for AWS terraform config)
    if ! command -v jq &>/dev/null; then
        missing+=("jq")
    fi

    # Check sshpass
    if ! command -v sshpass &>/dev/null; then
        echo -e "${RED}ERROR: sshpass is required but not installed.${NC}"
        echo ""
        echo "Install on macOS:"
        echo "  brew install hudochenkov/sshpass/sshpass"
        echo ""
        echo "Install on Ubuntu/Debian:"
        echo "  sudo apt-get install sshpass"
        echo ""
        exit 1
    fi

    # Check provider-specific CLI
    case "${provider}" in
        aws)
            if ! command -v aws &>/dev/null; then
                missing+=("aws CLI")
            elif ! aws sts get-caller-identity &>/dev/null; then
                echo -e "${RED}ERROR: AWS CLI not authenticated. Run 'aws configure' first.${NC}"
                exit 1
            fi
            ;;
        azure)
            if ! command -v az &>/dev/null; then
                missing+=("az CLI")
            elif ! az account show &>/dev/null; then
                echo -e "${RED}ERROR: Azure CLI not authenticated. Run 'az login' first.${NC}"
                exit 1
            fi
            ;;
        gcp)
            if ! command -v gcloud &>/dev/null; then
                missing+=("gcloud CLI")
            elif ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null \
                    | head -1 \
                    | grep -q '@'; then
                echo -e "${RED}ERROR: GCP CLI not authenticated. Run 'gcloud auth login' first.${NC}"
                exit 1
            fi
            ;;
    esac

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}ERROR: Missing required tools: ${missing[*]}${NC}"
        exit 1
    fi

    echo -e "${GREEN}Prerequisites OK${NC}"
}

# =============================================================================
# TERRAFORM OPERATIONS
# =============================================================================

# Get provider-specific terraform variable flags
# Arguments:
#   $1 - Cloud provider name (aws, azure, gcp)
# Returns:
#   Terraform variable flags via stdout
_get_provider_vars() {
    local provider="$1"

    case "${provider}" in
        azure)
            local subscription_id
            subscription_id=$(az account show --query id -o tsv)
            echo "-var=subscription_id=${subscription_id}"
            ;;
        gcp)
            local project_id
            project_id=$(gcloud config get-value project 2>/dev/null)
            if [[ -z "${project_id}" ]]; then
                _log ERROR "No GCP project set. Run 'gcloud config set project PROJECT_ID'"
                exit 1
            fi
            echo "-var=gcp_project=${project_id}"
            ;;
        *)
            # AWS and others don't need extra vars
            echo ""
            ;;
    esac
}

# Deploy infrastructure using Terraform
# Arguments:
#   $1 - Cloud provider name (aws, azure, gcp)
_terraform_apply() {
    local provider="$1"
    local provider_dir="${REPO_ROOT}/${provider}"
    local provider_vars

    _log INFO "Deploying ${provider} infrastructure..."
    cd "${provider_dir}"

    # Use -upgrade to ensure latest compatible provider versions (avoids stale lock file issues)
    terraform init -input=false -upgrade

    provider_vars=$(_get_provider_vars "${provider}")
    # shellcheck disable=SC2086
    terraform apply -auto-approve ${provider_vars} -var="use_local_setup=true"

    cd - > /dev/null
}

# Destroy infrastructure using Terraform
# Arguments:
#   $1 - Cloud provider name (aws, azure, gcp)
_terraform_destroy() {
    local provider="$1"
    local provider_dir="${REPO_ROOT}/${provider}"
    local provider_vars

    _log INFO "Destroying ${provider} infrastructure..."
    cd "${provider_dir}"

    provider_vars=$(_get_provider_vars "${provider}")
    # shellcheck disable=SC2086
    terraform destroy -auto-approve ${provider_vars}

    cd - > /dev/null
}

# Get the public IP address of the deployed VM
# Arguments:
#   $1 - Cloud provider name (aws, azure, gcp)
# Returns:
#   Public IP address via stdout, or returns 1 on failure
_get_public_ip() {
    local provider="$1"
    local provider_dir="${REPO_ROOT}/${provider}"
    local ip

    cd "${provider_dir}"
    ip=$(terraform output -raw public_ip_address 2>/dev/null \
        || terraform output -raw public_ip 2>/dev/null \
        || echo "")
    cd - > /dev/null

    # Validate IP format
    if [[ ! "${ip}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        _log ERROR "Invalid IP address retrieved: '${ip}'"
        return 1
    fi

    echo "${ip}"
}

# =============================================================================
# VM OPERATIONS
# =============================================================================

# Wait for SSH to become available on a VM
# Arguments:
#   $1 - IP address of the VM
# Returns:
#   0 on success, 1 on timeout
_wait_for_ssh() {
    local ip="$1"
    local attempt=1

    _log INFO "Waiting for SSH to become available at ${ip}..."

    while [[ ${attempt} -le ${MAX_SSH_ATTEMPTS} ]]; do
        # shellcheck disable=SC2086
        if _sshpass_cmd ssh ${SSH_OPTS} "${SSH_USER}@${ip}" "echo 'SSH OK'" &>/dev/null; then
            _log OK "SSH is available"
            return 0
        fi
        echo "  Attempt ${attempt}/${MAX_SSH_ATTEMPTS} - waiting..."
        sleep "${SSH_RETRY_INTERVAL}"
        ((attempt++))
    done

    _log ERROR "SSH connection timed out"
    return 1
}

# Reboot/restart a VM and return the new IP address
# Arguments:
#   $1 - Cloud provider name (aws, azure, gcp)
#   $2 - Current IP address of the VM
# Returns:
#   New IP address via stdout (may change for AWS)
_reboot_vm() {
    local provider="$1"
    local ip="$2"

    _log INFO "Rebooting VM (${provider})..."

    case "${provider}" in
        aws)
            local instance_id
            instance_id=$(cd "${REPO_ROOT}/${provider}" \
                && terraform output -raw instance_id 2>/dev/null \
                || aws ec2 describe-instances \
                    --filters "Name=ip-address,Values=${ip}" \
                    --query 'Reservations[0].Instances[0].InstanceId' \
                    --output text)

            # Validate instance ID
            if [[ -z "${instance_id}" ]] || [[ "${instance_id}" == "None" ]]; then
                _log ERROR "Failed to retrieve AWS instance ID for IP ${ip}"
                return 1
            fi

            echo "  Stopping instance ${instance_id}..."
            aws ec2 stop-instances --instance-ids "${instance_id}" > /dev/null
            aws ec2 wait instance-stopped --instance-ids "${instance_id}"
            echo "  Starting instance ${instance_id}..."
            aws ec2 start-instances --instance-ids "${instance_id}" > /dev/null
            aws ec2 wait instance-running --instance-ids "${instance_id}"
            # IP may change, get new one
            sleep 10
            ip=$(_get_public_ip "${provider}")
            ;;
        azure)
            echo "  Restarting Azure VM..."
            az vm restart --resource-group ctf-resources --name ctf-vm
            # az vm restart waits by default, but add explicit wait for running state
            az vm wait \
                --resource-group ctf-resources \
                --name ctf-vm \
                --created \
                --timeout 120 2>/dev/null || true
            ;;
        gcp)
            echo "  Restarting GCP VM..."
            local zone
            zone=$(cd "${REPO_ROOT}/${provider}" \
                && terraform output -raw zone 2>/dev/null \
                || echo "us-central1-a")
            gcloud compute instances reset ctf-instance --zone="${zone}" --quiet
            # Wait for VM to be running
            local attempts=0
            while [[ ${attempts} -lt 30 ]]; do
                local status
                status=$(gcloud compute instances describe ctf-instance \
                    --zone="${zone}" \
                    --format='value(status)' 2>/dev/null || echo "")
                if [[ "${status}" == "RUNNING" ]]; then
                    break
                fi
                sleep 2
                ((attempts++))
            done
            ;;
    esac

    # Return new IP (may have changed for AWS)
    echo "${ip}"
}

# =============================================================================
# TEST EXECUTION
# =============================================================================

# Copy test script to VM and execute it
# Arguments:
#   $1 - Cloud provider name
#   $2 - IP address of the VM
# Returns:
#   Exit code from the test script (0=pass, 1=fail, 100=reboot requested)
_run_tests() {
    local provider="$1"
    local ip="$2"
    local test_flags=""

    if [[ "${WITH_REBOOT}" == true ]]; then
        test_flags="${test_flags} --with-reboot"
    fi

    _log INFO "Copying test script to VM..."
    # shellcheck disable=SC2086
    _sshpass_cmd scp ${SSH_OPTS} "${TEST_SCRIPT}" "${SSH_USER}@${ip}:/tmp/test_ctf_challenges.sh"

    _log INFO "Running tests on ${provider} VM (${ip})..."
    echo ""

    local exit_code=0
    # shellcheck disable=SC2086
    _sshpass_cmd ssh ${SSH_OPTS} "${SSH_USER}@${ip}" \
        "chmod +x /tmp/test_ctf_challenges.sh && /tmp/test_ctf_challenges.sh ${test_flags}" \
        || exit_code=$?

    return "${exit_code}"
}

# Run tests after VM reboot to verify services persist
# Arguments:
#   $1 - Cloud provider name
#   $2 - IP address of the VM
# Returns:
#   Exit code from the test script
_run_post_reboot_tests() {
    local provider="$1"
    local ip="$2"

    _log INFO "Running post-reboot verification on ${provider}..."

    local exit_code=0
    # shellcheck disable=SC2086
    _sshpass_cmd ssh ${SSH_OPTS} "${SSH_USER}@${ip}" "/tmp/test_ctf_challenges.sh" \
        || exit_code=$?

    return "${exit_code}"
}

# =============================================================================
# MAIN TEST FLOW
# =============================================================================

# Run full test cycle for a single cloud provider
# Arguments:
#   $1 - Cloud provider name (aws, azure, gcp)
# Returns:
#   0 on success, 1 on failure
_test_provider() {
    local provider="$1"
    local result=0

    # Enable cleanup on interrupt for this provider
    CURRENT_PROVIDER="${provider}"
    CLEANUP_ON_EXIT=true

    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  TESTING: ${provider}${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Check prerequisites
    _check_prerequisites "${provider}"

    # Deploy
    if ! _terraform_apply "${provider}"; then
        _log ERROR "Terraform apply failed for ${provider}"
        CLEANUP_ON_EXIT=false
        _terraform_destroy "${provider}" 2>/dev/null || true
        CURRENT_PROVIDER=""
        return 1
    fi

    # Get IP
    local ip
    if ! ip=$(_get_public_ip "${provider}"); then
        _log ERROR "Failed to get valid IP address for ${provider}"
        CLEANUP_ON_EXIT=false
        _terraform_destroy "${provider}" 2>/dev/null || true
        CURRENT_PROVIDER=""
        return 1
    fi
    _log OK "VM deployed at: ${ip}"

    # Wait for SSH
    if ! _wait_for_ssh "${ip}"; then
        _log ERROR "SSH connection failed for ${provider}"
        CLEANUP_ON_EXIT=false
        _terraform_destroy "${provider}"
        CURRENT_PROVIDER=""
        return 1
    fi

    # Run tests
    local test_exit_code=0
    _run_tests "${provider}" "${ip}" || test_exit_code=$?

    # Handle reboot test
    if [[ ${test_exit_code} -eq 100 ]] && [[ "${WITH_REBOOT}" == true ]]; then
        echo ""
        _log WARN "Reboot requested - performing VM reboot..."

        local new_ip
        new_ip=$(_reboot_vm "${provider}" "${ip}")

        # Wait for SSH after reboot
        _wait_for_ssh "${new_ip}"

        # Run post-reboot tests
        _run_post_reboot_tests "${provider}" "${new_ip}" || test_exit_code=$?
    elif [[ ${test_exit_code} -ne 0 ]]; then
        result=1
    fi

    # Cleanup
    echo ""
    CLEANUP_ON_EXIT=false
    _terraform_destroy "${provider}"
    CURRENT_PROVIDER=""

    return "${result}"
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

# Main function - orchestrates testing across all specified providers
_main() {
    local failed_providers=()
    local passed_providers=()

    _log WARN "CTF Challenge Test Suite"
    echo "Providers to test: ${PROVIDERS_TO_TEST[*]}"
    echo "Reboot test: ${WITH_REBOOT}"
    echo ""

    for provider in "${PROVIDERS_TO_TEST[@]}"; do
        if _test_provider "${provider}"; then
            passed_providers+=("${provider}")
        else
            failed_providers+=("${provider}")
        fi
    done

    # Final summary (short pass/fail)
    echo ""
    if [[ ${#failed_providers[@]} -gt 0 ]]; then
        _log ERROR "RESULT: FAIL (${failed_providers[*]})"
        exit 1
    fi

    _log OK "RESULT: PASS (${passed_providers[*]})"
    exit 0
}

_main
