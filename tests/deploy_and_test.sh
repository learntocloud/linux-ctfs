#!/bin/bash
#
# CTF Deploy and Test Orchestration Script
# Deploys infrastructure to cloud providers and runs tests
#
# Usage:
#   ./deploy_and_test.sh <aws|azure|gcp|all> [--with-reboot]
#
# Arguments:
#   aws|azure|gcp|all    Cloud provider(s) to test
#   --with-reboot        After initial tests pass, stop/start the VM and
#                        re-run verification to ensure services survive
#                        reboot and progress persists
#
# Prerequisites:
#   - terraform (>= 1.0)
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

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_SCRIPT="$SCRIPT_DIR/test_ctf_challenges.sh"

# SSH settings
SSH_USER="ctf_user"
SSH_PASS="CTFpassword123!"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
WITH_REBOOT=false
PROVIDERS_TO_TEST=()

for arg in "$@"; do
    case $arg in
        aws|azure|gcp)
            PROVIDERS_TO_TEST+=("$arg")
            ;;
        all)
            PROVIDERS_TO_TEST=("aws" "azure" "gcp")
            ;;
        --with-reboot)
            WITH_REBOOT=true
            ;;
        -h|--help)
            head -30 "$0" | tail -28
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 <aws|azure|gcp|all> [--with-reboot]"
            exit 1
            ;;
    esac
done

if [ ${#PROVIDERS_TO_TEST[@]} -eq 0 ]; then
    echo "Usage: $0 <aws|azure|gcp|all> [--with-reboot]"
    exit 1
fi

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

check_prerequisites() {
    local provider="$1"
    local missing=()
    
    echo -e "${BLUE}Checking prerequisites for $provider...${NC}"
    
    # Check terraform
    if ! command -v terraform &>/dev/null; then
        missing+=("terraform")
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
    case $provider in
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
            elif ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1 | grep -q '@'; then
                echo -e "${RED}ERROR: GCP CLI not authenticated. Run 'gcloud auth login' first.${NC}"
                exit 1
            fi
            ;;
    esac
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}ERROR: Missing required tools: ${missing[*]}${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Prerequisites OK${NC}"
}

# ============================================================================
# TERRAFORM OPERATIONS
# ============================================================================

terraform_apply() {
    local provider="$1"
    local provider_dir="$REPO_ROOT/$provider"
    
    echo -e "${BLUE}Deploying $provider infrastructure...${NC}"
    cd "$provider_dir"
    
    terraform init -input=false
    
    # Handle provider-specific variables
    # use_local_setup=true to test with local ctf_setup.sh instead of GitHub
    case $provider in
        azure)
            local subscription_id
            subscription_id=$(az account show --query id -o tsv)
            terraform apply -auto-approve -var="subscription_id=$subscription_id" -var="use_local_setup=true"
            ;;
        gcp)
            local project_id
            project_id=$(gcloud config get-value project 2>/dev/null)
            if [ -z "$project_id" ]; then
                echo -e "${RED}ERROR: No GCP project set. Run 'gcloud config set project PROJECT_ID'${NC}"
                exit 1
            fi
            terraform apply -auto-approve -var="gcp_project=$project_id" -var="use_local_setup=true"
            ;;
        *)
            terraform apply -auto-approve -var="use_local_setup=true"
            ;;
    esac
    
    cd - > /dev/null
}

terraform_destroy() {
    local provider="$1"
    local provider_dir="$REPO_ROOT/$provider"
    
    echo -e "${BLUE}Destroying $provider infrastructure...${NC}"
    cd "$provider_dir"
    
    case $provider in
        azure)
            local subscription_id
            subscription_id=$(az account show --query id -o tsv)
            terraform destroy -auto-approve -var="subscription_id=$subscription_id"
            ;;
        gcp)
            local project_id
            project_id=$(gcloud config get-value project 2>/dev/null)
            terraform destroy -auto-approve -var="gcp_project=$project_id"
            ;;
        *)
            terraform destroy -auto-approve
            ;;
    esac
    
    cd - > /dev/null
}

get_public_ip() {
    local provider="$1"
    local provider_dir="$REPO_ROOT/$provider"
    
    cd "$provider_dir"
    terraform output -raw public_ip_address 2>/dev/null || terraform output -raw public_ip 2>/dev/null
    cd - > /dev/null
}

# ============================================================================
# VM OPERATIONS
# ============================================================================

wait_for_ssh() {
    local ip="$1"
    local max_attempts=30
    local attempt=1
    
    echo -e "${BLUE}Waiting for SSH to become available at $ip...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if sshpass -p "$SSH_PASS" ssh $SSH_OPTS "$SSH_USER@$ip" "echo 'SSH OK'" &>/dev/null; then
            echo -e "${GREEN}SSH is available${NC}"
            return 0
        fi
        echo "  Attempt $attempt/$max_attempts - waiting..."
        sleep 10
        ((attempt++))
    done
    
    echo -e "${RED}SSH connection timed out${NC}"
    return 1
}

reboot_vm() {
    local provider="$1"
    local ip="$2"
    
    echo -e "${BLUE}Rebooting VM ($provider)...${NC}"
    
    case $provider in
        aws)
            local instance_id
            instance_id=$(cd "$REPO_ROOT/$provider" && terraform output -raw instance_id 2>/dev/null || \
                aws ec2 describe-instances --filters "Name=ip-address,Values=$ip" --query 'Reservations[0].Instances[0].InstanceId' --output text)
            echo "  Stopping instance $instance_id..."
            aws ec2 stop-instances --instance-ids "$instance_id" > /dev/null
            aws ec2 wait instance-stopped --instance-ids "$instance_id"
            echo "  Starting instance $instance_id..."
            aws ec2 start-instances --instance-ids "$instance_id" > /dev/null
            aws ec2 wait instance-running --instance-ids "$instance_id"
            # IP may change, get new one
            sleep 10
            ip=$(get_public_ip "$provider")
            ;;
        azure)
            echo "  Restarting Azure VM..."
            az vm restart --resource-group ctf-resources --name ctf-vm --no-wait
            sleep 30
            ;;
        gcp)
            echo "  Restarting GCP VM..."
            local zone
            zone=$(cd "$REPO_ROOT/$provider" && terraform output -raw zone 2>/dev/null || echo "us-central1-a")
            gcloud compute instances reset ctf-instance --zone="$zone" --quiet
            sleep 30
            ;;
    esac
    
    # Return new IP (may have changed for AWS)
    echo "$ip"
}

# ============================================================================
# TEST EXECUTION
# ============================================================================

run_tests() {
    local provider="$1"
    local ip="$2"
    local reboot_flag=""
    
    if [ "$WITH_REBOOT" = true ]; then
        reboot_flag="--with-reboot"
    fi
    
    echo -e "${BLUE}Copying test script to VM...${NC}"
    sshpass -p "$SSH_PASS" scp $SSH_OPTS "$TEST_SCRIPT" "$SSH_USER@$ip:/tmp/test_ctf_challenges.sh"
    
    echo -e "${BLUE}Running tests on $provider VM ($ip)...${NC}"
    echo ""
    
    local exit_code=0
    sshpass -p "$SSH_PASS" ssh $SSH_OPTS "$SSH_USER@$ip" "chmod +x /tmp/test_ctf_challenges.sh && /tmp/test_ctf_challenges.sh $reboot_flag" || exit_code=$?
    
    return $exit_code
}

run_post_reboot_tests() {
    local provider="$1"
    local ip="$2"
    
    echo -e "${BLUE}Running post-reboot verification on $provider...${NC}"
    
    local exit_code=0
    sshpass -p "$SSH_PASS" ssh $SSH_OPTS "$SSH_USER@$ip" "/tmp/test_ctf_challenges.sh" || exit_code=$?
    
    return $exit_code
}

# ============================================================================
# MAIN TEST FLOW
# ============================================================================

test_provider() {
    local provider="$1"
    local result=0
    
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  TESTING: $provider${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites "$provider"
    
    # Deploy
    terraform_apply "$provider"
    
    # Get IP
    local ip
    ip=$(get_public_ip "$provider")
    echo -e "${GREEN}VM deployed at: $ip${NC}"
    
    # Wait for SSH
    wait_for_ssh "$ip"
    
    # Run tests
    local test_exit_code=0
    run_tests "$provider" "$ip" || test_exit_code=$?
    
    # Handle reboot test
    if [ $test_exit_code -eq 100 ] && [ "$WITH_REBOOT" = true ]; then
        echo ""
        echo -e "${YELLOW}Reboot requested - performing VM reboot...${NC}"
        
        local new_ip
        new_ip=$(reboot_vm "$provider" "$ip")
        
        # Wait for SSH after reboot
        wait_for_ssh "$new_ip"
        
        # Run post-reboot tests
        run_post_reboot_tests "$provider" "$new_ip" || test_exit_code=$?
    elif [ $test_exit_code -ne 0 ]; then
        result=1
    fi
    
    # Cleanup
    echo ""
    terraform_destroy "$provider"
    
    return $result
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local failed_providers=()
    local passed_providers=()
    
    echo -e "${YELLOW}CTF Challenge Test Suite${NC}"
    echo "Providers to test: ${PROVIDERS_TO_TEST[*]}"
    echo "Reboot test: $WITH_REBOOT"
    echo ""
    
    for provider in "${PROVIDERS_TO_TEST[@]}"; do
        if test_provider "$provider"; then
            passed_providers+=("$provider")
        else
            failed_providers+=("$provider")
        fi
    done
    
    # Final summary
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  FINAL RESULTS${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ ${#passed_providers[@]} -gt 0 ]; then
        echo -e "${GREEN}PASSED: ${passed_providers[*]}${NC}"
    fi
    
    if [ ${#failed_providers[@]} -gt 0 ]; then
        echo -e "${RED}FAILED: ${failed_providers[*]}${NC}"
        exit 1
    fi
    
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
}

main
