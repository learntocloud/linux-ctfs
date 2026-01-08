#!/bin/bash
#
# CTF Environment Setup Script
# Sets up 18 Linux command-line challenges for learning
#
set -euo pipefail

# =============================================================================
# DYNAMIC FLAG GENERATION
# =============================================================================
# Generate unique flags for this instance to prevent answer sharing
# Each flag has format: CTF{descriptive_text_XXXX} where XXXX is random hex

generate_flag_suffix() {
    head -c 4 /dev/urandom | xxd -p
}

# Generate unique suffix for this instance
INSTANCE_SUFFIX=$(generate_flag_suffix)

# Define flag base names (the descriptive part)
declare -A FLAG_BASES=(
    [0]="example"
    [1]="finding_hidden_treasures"
    [2]="search_and_discover"
    [3]="size_matters_in_linux"
    [4]="user_enumeration_expert"
    [5]="permission_sleuth"
    [6]="network_detective"
    [7]="decoding_master"
    [8]="ssh_security_master"
    [9]="dns_name"
    [10]="network_copy"
    [11]="web_config"
    [12]="net_chat"
    [13]="cron_task_master"
    [14]="env_variable_hunter"
    [15]="archive_explorer"
    [16]="link_follower"
    [17]="history_detective"
    [18]="disk_detective"
)

# Generate the actual flags with unique suffix
declare -A FLAGS
for i in {0..18}; do
    if [ "$i" -eq 0 ]; then
        # Example flag stays static so documentation works
        FLAGS[$i]="CTF{example}"
    else
        FLAGS[$i]="CTF{${FLAG_BASES[$i]}_${INSTANCE_SUFFIX}}"
    fi
done

# Generate SHA256 hashes for verification
declare -A FLAG_HASHES
for i in {0..18}; do
    FLAG_HASHES[$i]=$(echo -n "${FLAGS[$i]}" | sha256sum | cut -d' ' -f1)
done

# =============================================================================
# SYSTEM SETUP
# =============================================================================

# System setup
sudo apt-get update
sudo apt-get install -y net-tools nmap tree nginx inotify-tools figlet lolcat

# Disable default Ubuntu MOTD
sudo chmod -x /etc/update-motd.d/00-header 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/10-help-text 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/50-landscape-sysinfo 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/80-esm 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/80-livepatch 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/90-updates-available 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/91-release-upgrade 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/92-unattended-upgrades 2>/dev/null || true
sudo chmod -x /etc/update-motd.d/95-hwe-eol 2>/dev/null || true

# Create CTF user (if not exists)
if ! id "ctf_user" &>/dev/null; then
    sudo useradd -m -s /bin/bash ctf_user
    echo 'ctf_user:CTFpassword123!' | sudo chpasswd
    sudo usermod -aG sudo ctf_user
fi

# Fix for unknown terminal types (e.g., ghostty)
# shellcheck disable=SC2016 # Single quotes intentional - $TERM should expand at login time
echo 'case "$TERM" in *-ghostty) export TERM=xterm-256color;; esac' | sudo tee /etc/profile.d/fix-term.sh > /dev/null
sudo chmod 644 /etc/profile.d/fix-term.sh

# SSH configuration
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Create challenge directory
sudo -u ctf_user mkdir -p /home/ctf_user/ctf_challenges
cd /home/ctf_user/ctf_challenges || { echo "Failed to change directory"; exit 1; }

# =============================================================================
# WRITE FLAG HASHES FILE (for verify script)
# =============================================================================
# Store hashes in a root-owned file that verify can read but users can't easily modify
sudo mkdir -p /etc/ctf
cat > /tmp/ctf_hashes << HASHEOF
${FLAG_HASHES[0]}
${FLAG_HASHES[1]}
${FLAG_HASHES[2]}
${FLAG_HASHES[3]}
${FLAG_HASHES[4]}
${FLAG_HASHES[5]}
${FLAG_HASHES[6]}
${FLAG_HASHES[7]}
${FLAG_HASHES[8]}
${FLAG_HASHES[9]}
${FLAG_HASHES[10]}
${FLAG_HASHES[11]}
${FLAG_HASHES[12]}
${FLAG_HASHES[13]}
${FLAG_HASHES[14]}
${FLAG_HASHES[15]}
${FLAG_HASHES[16]}
${FLAG_HASHES[17]}
${FLAG_HASHES[18]}
HASHEOF
sudo mv /tmp/ctf_hashes /etc/ctf/flag_hashes
sudo chmod 644 /etc/ctf/flag_hashes

# Create verify script
sudo tee /usr/local/bin/verify > /dev/null << 'EOFVERIFY'
#!/bin/bash

# Load flag hashes from file (generated at setup time)
HASH_FILE="/etc/ctf/flag_hashes"
if [ ! -f "$HASH_FILE" ]; then
    echo "Error: CTF not properly initialized. Hash file missing."
    exit 1
fi

# Read hashes into array
mapfile -t ANSWER_HASHES < "$HASH_FILE"

CHALLENGE_NAMES=(
    "Example Challenge"
    "Hidden File Discovery"
    "Basic File Search"
    "Log Analysis"
    "User Investigation"
    "Permission Analysis"
    "Service Discovery"
    "Encoding Challenge"
    "SSH Secrets"
    "DNS Troubleshooting"
    "Remote Upload Detection"
    "Web Configuration"
    "Network Traffic Analysis"
    "Cron Job Hunter"
    "Process Environment"
    "Archive Archaeologist"
    "Symbolic Sleuth"
    "History Mystery"
    "Disk Detective"
)

CHALLENGE_HINTS=(
    "Run: verify 0 CTF{example}"
    "Hidden files in Linux start with a dot. Try 'ls -la' in the ctf_challenges directory."
    "Use the 'find' command to search for files. Try: find ~ -name '*.txt' 2>/dev/null"
    "Large log files can hide secrets. Check /var/log and use 'tail' to see the end of files."
    "Investigate other users on the system. Check /etc/passwd or use 'getent passwd'."
    "Look for files with unusual permissions. Try: find / -perm 777 2>/dev/null"
    "What services are running? Use 'netstat -tulpn' or 'ss -tulpn' to find listening ports."
    "The flag is encoded. Look for encoded files and use 'base64 -d' to decode."
    "SSH configurations often hide secrets. Explore ~/.ssh directory thoroughly."
    "DNS settings are stored in /etc/resolv.conf. Examine it carefully."
    "Monitor file creation with tools like inotifywait, or try creating a file in ctf_challenges."
    "Web servers serve content from specific directories. Check what ports nginx is listening on."
    "Network traffic can carry hidden messages. Look at ping patterns with tcpdump."
    "Cron jobs run on schedules. Check /etc/cron.d/, /etc/crontab, and user crontabs with 'crontab -l'."
    "Process info lives in /proc. Each process has a directory with its environment in /proc/PID/environ."
    "Archives can be nested. Use 'tar -xzf' or 'gunzip' to extract layers. Check file types with 'file' command."
    "Symlinks can chain together. Use 'readlink -f' to find the final target, or 'ls -la' to see link targets."
    "Bash stores command history in ~/.bash_history. Other users may have history files too."
    "A disk image file exists on the system. Try mounting it with 'sudo mount -o loop <image> <mountpoint>' to explore its contents."
)

START_TIME_FILE=~/.ctf_start_time

check_flag() {
    local challenge_num=$1
    local submitted_flag=$2
    
    # Validate challenge number is within bounds
    if ! [[ "$challenge_num" =~ ^[0-9]+$ ]] || [ "$challenge_num" -gt 18 ]; then
        echo "✗ Invalid challenge number. Use 0-18."
        return 1
    fi
    
    local submitted_hash
    submitted_hash=$(echo -n "$submitted_flag" | sha256sum | cut -d' ' -f1)
    
    if [ "$submitted_hash" = "${ANSWER_HASHES[$challenge_num]}" ]; then
        if [ "$challenge_num" -eq 0 ]; then
            echo "✓ Example flag verified! Now try finding real flags."
        else
            echo "✓ Correct flag for Challenge $challenge_num!"
        fi
        echo "$challenge_num" >> ~/.completed_challenges
        sort -u ~/.completed_challenges > ~/.completed_challenges.tmp
        mv ~/.completed_challenges.tmp ~/.completed_challenges
    else
        echo "✗ Incorrect flag. Try again!"
    fi
    show_progress
}

show_progress() {
    local completed=0
    if [ -f ~/.completed_challenges ]; then
        completed=$(sort -u ~/.completed_challenges | wc -l)
        completed=$((completed-1)) # Subtract example challenge
    fi
    echo "Flags Found: $completed/18"
    if [ "$completed" -eq 18 ]; then
        echo "Congratulations! You've completed all challenges!"
    fi
}

init_timer() {
    if [ ! -f "$START_TIME_FILE" ]; then
        date +%s > "$START_TIME_FILE"
    fi
}

show_time() {
    if [ ! -f "$START_TIME_FILE" ]; then
        echo "Timer not started. Complete your first challenge to start the timer."
        return
    fi
    local start_time=$(cat "$START_TIME_FILE")
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))
    local seconds=$((elapsed % 60))
    printf "Elapsed Time: %02d:%02d:%02d\n" $hours $minutes $seconds
}

show_list() {
    echo "======================================"
    echo "       CTF Challenge Status"
    echo "======================================"
    for i in {0..18}; do
        local status="[ ]"
        if [ -f ~/.completed_challenges ] && grep -q "^${i}$" ~/.completed_challenges; then
            status="[✓]"
        fi
        if [ $i -eq 0 ]; then
            printf "%s %2d. %s (Example)\n" "$status" "$i" "${CHALLENGE_NAMES[$i]}"
        else
            printf "%s %2d. %s\n" "$status" "$i" "${CHALLENGE_NAMES[$i]}"
        fi
    done
    echo "======================================"
    show_progress
}

show_hint() {
    local num="${1:-}"
    if [[ -z "$num" ]] || ! [[ "$num" =~ ^[0-9]+$ ]] || [[ "$num" -gt 18 ]]; then
        echo "Usage: verify hint [0-18]"
        return 1
    fi
    echo "======================================"
    echo "Hint for Challenge $num: ${CHALLENGE_NAMES[$num]}"
    echo "======================================"
    echo "${CHALLENGE_HINTS[$num]}"
    echo "======================================"
}

export_certificate() {
    # Check completion status first (more helpful error message)
    local completed=0
    if [ -f ~/.completed_challenges ]; then
        completed=$(sort -u ~/.completed_challenges | wc -l)
        completed=$((completed-1))
    fi
    
    if [ "$completed" -lt 18 ]; then
        echo "Complete all 18 challenges to earn your certificate!"
        echo "Current progress: $completed/18"
        return 1
    fi
    
    # Now check for name argument
    if [ -z "$1" ]; then
        echo "Usage: verify export <name>"
        echo "Example: verify export John Doe"
        return 1
    fi
    local custom_name="$1"
    
    local completion_time="Unknown"
    if [ -f "$START_TIME_FILE" ]; then
        local start_time=$(cat "$START_TIME_FILE")
        local end_time=$(date +%s)
        local elapsed=$((end_time - start_time))
        local hours=$((elapsed / 3600))
        local minutes=$(((elapsed % 3600) / 60))
        completion_time=$(printf "%02d:%02d" $hours $minutes)
    fi
    
    local cert_file=~/ctf_certificate_$(date +%Y%m%d_%H%M%S).txt
    
    # Display fancy certificate to terminal
    echo ""
    echo "============================================================" | lolcat
    echo "         LEARN TO CLOUD - CTF COMPLETION CERTIFICATE        " | lolcat
    echo "============================================================" | lolcat
    echo ""
    echo "  This certifies that"
    echo ""
    figlet -c "$custom_name" | lolcat
    echo ""
    echo "  has successfully completed all 18 Linux CTF challenges"
    echo ""
    echo "  Completion Time: $completion_time"
    echo "  Date: $(date +%Y-%m-%d)"
    echo ""
    echo "  Challenges Completed:"
    echo "   * Hidden File Discovery      * Service Discovery"
    echo "   * Basic File Search          * Encoding Challenge"
    echo "   * Log Analysis               * SSH Secrets"
    echo "   * User Investigation         * DNS Troubleshooting"
    echo "   * Permission Analysis        * Remote Upload Detection"
    echo "   * Web Configuration          * Network Traffic Analysis"
    echo "   * Cron Job Hunter            * Process Environment"
    echo "   * Archive Archaeologist      * Symbolic Sleuth"
    echo "   * History Mystery            * Disk Detective"
    echo ""
    echo "============================================================" | lolcat
    echo "                 🎉 Congratulations! 🎉                      " | lolcat
    echo "============================================================" | lolcat
    
    # Save plain text version to file
    cat > "$cert_file" << CERTEOF
============================================================
         LEARN TO CLOUD - CTF COMPLETION CERTIFICATE
============================================================

  This certifies that

              $custom_name

  has successfully completed all 18 Linux CTF challenges

  Completion Time: $completion_time
  Date: $(date +%Y-%m-%d)

  Challenges Completed:
   * Hidden File Discovery      * Service Discovery
   * Basic File Search          * Encoding Challenge
   * Log Analysis               * SSH Secrets
   * User Investigation         * DNS Troubleshooting
   * Permission Analysis        * Remote Upload Detection
   * Web Configuration          * Network Traffic Analysis
   * Cron Job Hunter            * Process Environment
   * Archive Archaeologist      * Symbolic Sleuth
   * History Mystery            * Disk Detective

============================================================
                    Congratulations!
============================================================
CERTEOF
    echo ""
    echo "Certificate exported to: $cert_file"
}

case "$1" in
    "progress")
        show_progress
        ;;
    "list")
        show_list
        ;;
    "hint")
        show_hint "${2:?Usage: verify hint [0-18]}"
        ;;
    "time")
        show_time
        ;;
    "export")
        shift
        export_certificate "$*"
        ;;
    [0-9]|1[0-8])
        init_timer
        check_flag "$1" "${2:?Usage: verify [challenge_number] [flag]}"
        ;;
    *)
        echo "Usage:"
        echo "  verify [challenge_number] [flag] - Check a flag"
        echo "  verify progress - Show progress"
        echo "  verify list     - List all challenges with status"
        echo "  verify hint [n] - Show hint for challenge n"
        echo "  verify time     - Show elapsed time"
        echo "  verify export <name> - Export completion certificate with your name"
        echo
        echo "Example: verify 0 CTF{example}"
        ;;
esac
EOFVERIFY

sudo chmod +x /usr/local/bin/verify

# Create setup check script
cat > /usr/local/bin/check_setup << 'EOF'
#!/bin/bash
if [ ! -f /var/log/setup_complete ]; then
    echo "System is still being configured. Please wait..."
    exit 1
fi
EOF

chmod +x /usr/local/bin/check_setup

# Add to bash profile
echo "/usr/local/bin/check_setup" >> /home/ctf_user/.profile

# Create MOTD
cat > /etc/motd << 'EOFMOTD'
+==============================================+
|  Learn To Cloud - Linux Command Line CTF    |
+==============================================+

Welcome! Here are 18 Progressive Linux Challenges.
Refer to the readme for information on each challenge.

Once you find a flag, use our verify tool to check your answer
and review your progress.

Usage:
  verify [challenge number] [flag] - Submit flag for verification
  verify 0 CTF{example} - Example flag
  verify progress     - Shows your progress

  To capture first flag, run: verify 0 CTF{example}

Good luck!
Team L2C

+==============================================+
EOFMOTD

# Beginner Challenges
# Challenge 1: Simple hidden file
echo "${FLAGS[1]}" > /home/ctf_user/ctf_challenges/.hidden_flag

# Challenge 2: Basic file search
mkdir -p /home/ctf_user/documents/projects/backup
echo "${FLAGS[2]}" > /home/ctf_user/documents/projects/backup/secret_notes.txt

# Intermediate Challenges
# Challenge 3: Log analysis
sudo dd if=/dev/urandom of=/var/log/large_log_file.log bs=1M count=500
echo "${FLAGS[3]}" | sudo tee -a /var/log/large_log_file.log
sudo chown ctf_user:ctf_user /var/log/large_log_file.log

# Challenge 4: User investigation
sudo useradd -u 1002 -m flag_user 2>/dev/null || true
sudo mkdir -p /home/flag_user
echo "${FLAGS[4]}" | sudo tee /home/flag_user/.profile > /dev/null
sudo chown -R flag_user:flag_user /home/flag_user
sudo chmod 755 /home/flag_user
sudo chmod 644 /home/flag_user/.profile

# Challenge 5: Permission analysis
sudo mkdir -p /opt/systems/config
echo "${FLAGS[5]}" | sudo tee /opt/systems/config/system.conf
sudo chmod 777 /opt/systems/config/system.conf

# Advanced Challenges
# Challenge 6: Service discovery
# Note: We write the flag to a file that the service reads, so it can be dynamic
echo "${FLAGS[6]}" | sudo tee /etc/ctf/flag_6 > /dev/null
cat > /usr/local/bin/secret_service.sh << 'EOF'
#!/bin/bash
FLAG=$(cat /etc/ctf/flag_6)
FLAG_LEN=${#FLAG}
while true; do
    echo -e "HTTP/1.1 200 OK\r\nContent-Length: ${FLAG_LEN}\r\nConnection: close\r\n\r\n${FLAG}" | nc -l -q 1 8080
done
EOF
sudo chmod +x /usr/local/bin/secret_service.sh

# Create systemd service for Challenge 6
cat > /etc/systemd/system/ctf-secret-service.service << 'EOF'
[Unit]
Description=CTF Secret Service Challenge
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/secret_service.sh
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now ctf-secret-service

# Challenge 7: Encoding challenge
echo "${FLAGS[7]}" | base64 | base64 > /home/ctf_user/ctf_challenges/encoded_flag.txt

# Challenge 8: Advanced SSH setup
sudo mkdir -p /home/ctf_user/.ssh/secrets/backup
echo "${FLAGS[8]}" | sudo tee /home/ctf_user/.ssh/secrets/backup/.authorized_keys
sudo chown -R ctf_user:ctf_user /home/ctf_user/.ssh
sudo chmod 700 /home/ctf_user/.ssh
sudo chmod 600 /home/ctf_user/.ssh/secrets/backup/.authorized_keys

# Challenge 9: DNS troubleshooting
sudo cp /etc/resolv.conf /etc/resolv.conf.bak
sudo sed -i "/^nameserver/s/$/${FLAGS[9]}/" /etc/resolv.conf

# Challenge 10: Remote upload
# Store flag for the monitor script to use
echo "${FLAGS[10]}" | sudo tee /etc/ctf/flag_10 > /dev/null
cat > /usr/local/bin/monitor_directory.sh << 'EOF'
#!/bin/bash
DIRECTORY="/home/ctf_user/ctf_challenges"
FLAG=$(cat /etc/ctf/flag_10)
# Pre-create the trigger file location
touch /tmp/.ctf_upload_triggered 2>/dev/null || true
chmod 666 /tmp/.ctf_upload_triggered 2>/dev/null || true
inotifywait -m -e create --format '%f' "$DIRECTORY" | while read FILE
do
    echo "A new file named $FILE has been added to $DIRECTORY. Here is your flag: $FLAG" | wall
    # Also write flag to file for automated testing
    echo "$FLAG" > /tmp/.ctf_upload_triggered
    sync
done
EOF

sudo chmod +x /usr/local/bin/monitor_directory.sh

# Create systemd service for Challenge 10
cat > /etc/systemd/system/ctf-monitor-directory.service << 'EOF'
[Unit]
Description=CTF Directory Monitor Challenge
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/local/bin/monitor_directory.sh
Restart=always
RestartSec=1
StandardOutput=append:/var/log/monitor_directory.log
StandardError=append:/var/log/monitor_directory.log

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now ctf-monitor-directory

# Challenge 11: Web Configuration
sudo mkdir -p /var/www/html
echo "<h2 style=\"text-align:center;\">Flag value: ${FLAGS[11]}</h2>" | sudo tee /var/www/html/index.html
sudo sed -i 's/listen 80 default_server;/listen 8083 default_server;/' /etc/nginx/sites-available/default
sudo sed -i 's/listen \[::\]:80 default_server;/listen \[::\]:8083 default_server;/' /etc/nginx/sites-available/default

sudo systemctl restart nginx

# Challenge 12: Network traffic analysis
# Convert flag to hex for ping pattern
FLAG_12_HEX=$(echo -n "${FLAGS[12]}" | xxd -p | tr -d '\n')
cat > /usr/local/bin/ping_message.sh << EOF
#!/bin/bash
while true; do
    ping -p ${FLAG_12_HEX} -c 1 127.0.0.1
    sleep 1
done
EOF

sudo chmod +x /usr/local/bin/ping_message.sh

# Create systemd service for Challenge 12
cat > /etc/systemd/system/ctf-ping-message.service << 'EOF'
[Unit]
Description=CTF Ping Message Challenge
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ping_message.sh
Restart=always
RestartSec=1
StandardOutput=append:/var/log/ping_message.log
StandardError=append:/var/log/ping_message.log

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now ctf-ping-message

# Challenge 13: Cron Job Hunter
cat > /etc/cron.d/ctf_secret_task << EOF
# CTF Challenge - Secret scheduled task
# This task runs every minute but the flag is hidden here
# FLAG: ${FLAGS[13]}
* * * * * root /bin/true
EOF
sudo chmod 644 /etc/cron.d/ctf_secret_task

# Challenge 14: Process Environment
# Store flag for the process to use
echo "${FLAGS[14]}" | sudo tee /etc/ctf/flag_14 > /dev/null
cat > /usr/local/bin/ctf_secret_process.sh << 'EOF'
#!/bin/bash
export CTF_SECRET_FLAG=$(cat /etc/ctf/flag_14)
while true; do
    sleep 3600
done
EOF
sudo chmod +x /usr/local/bin/ctf_secret_process.sh

# Create systemd service for Challenge 14
# Run as ctf_user so they can read /proc/PID/environ
cat > /etc/systemd/system/ctf-secret-process.service << EOF
[Unit]
Description=CTF Secret Process Challenge
After=network.target

[Service]
Type=simple
User=ctf_user
Group=ctf_user
Environment="CTF_SECRET_FLAG=${FLAGS[14]}"
ExecStart=/usr/local/bin/ctf_secret_process.sh
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now ctf-secret-process

# Challenge 15: Archive Archaeologist
CTF_ARCHIVE_TMPDIR=$(mktemp -d)
echo "${FLAGS[15]}" > "$CTF_ARCHIVE_TMPDIR/flag.txt"
(
    cd "$CTF_ARCHIVE_TMPDIR" || exit 1
    tar -czf inner.tar.gz flag.txt
    tar -czf middle.tar.gz inner.tar.gz
    tar -czf /home/ctf_user/ctf_challenges/mystery_archive.tar.gz middle.tar.gz
)
rm -rf "$CTF_ARCHIVE_TMPDIR"

# Challenge 16: Symbolic Sleuth
sudo mkdir -p /var/lib/ctf/secrets/deep/hidden
echo "${FLAGS[16]}" | sudo tee /var/lib/ctf/secrets/deep/hidden/final_flag.txt
sudo ln -s /var/lib/ctf/secrets/deep/hidden/final_flag.txt /var/lib/ctf/secrets/deep/link3
sudo ln -s /var/lib/ctf/secrets/deep/link3 /var/lib/ctf/secrets/link2
sudo ln -s /var/lib/ctf/secrets/link2 /home/ctf_user/ctf_challenges/follow_me
sudo chmod 755 /var/lib/ctf /var/lib/ctf/secrets /var/lib/ctf/secrets/deep /var/lib/ctf/secrets/deep/hidden
sudo chmod 644 /var/lib/ctf/secrets/deep/hidden/final_flag.txt

# Challenge 17: History Mystery
sudo useradd -m -s /bin/bash old_admin 2>/dev/null || true
sudo mkdir -p /home/old_admin
cat << HISTEOF | sudo tee /home/old_admin/.bash_history > /dev/null
# Old admin command history
ls -la
cd /var/log
# Note to self: the secret flag is ${FLAGS[17]}
sudo systemctl restart nginx
exit
HISTEOF
sudo chown -R old_admin:old_admin /home/old_admin
sudo chmod 755 /home/old_admin
sudo chmod 644 /home/old_admin/.bash_history

# Challenge 18: Disk Detective
# Create a small file system image with the flag stored inside
sudo dd if=/dev/zero of=/opt/ctf_disk.img bs=1M count=10
sudo mkfs.ext4 -L "ctf_disk" /opt/ctf_disk.img
sudo mkdir -p /mnt/ctf_disk
# Mount the image, create flag file, then unmount
sudo mount -o loop /opt/ctf_disk.img /mnt/ctf_disk
echo "${FLAGS[18]}" | sudo tee /mnt/ctf_disk/.flag > /dev/null
sudo umount /mnt/ctf_disk
# The flag is hidden inside the filesystem image - mount it to find it!

# Set permissions
sudo chown -R ctf_user:ctf_user /home/ctf_user/ctf_challenges

# Enable MOTD display in PAM
sudo sed -i 's/#session    optional     pam_motd.so/session    optional     pam_motd.so/' /etc/pam.d/login
sudo sed -i 's/#session    optional     pam_motd.so/session    optional     pam_motd.so/' /etc/pam.d/sshd
sudo systemctl restart ssh

# Fix hostname resolution for sudo
HOSTNAME=$(hostname)
if ! grep -qF "$HOSTNAME" /etc/hosts; then
    echo "127.0.0.1 $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi

# Mark setup as complete
touch /var/log/setup_complete

echo "CTF environment setup complete!"