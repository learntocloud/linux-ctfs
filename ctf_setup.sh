#!/bin/bash
#
# CTF Environment Setup Script
# Sets up 18 Linux command-line challenges for learning
#
set -euo pipefail

# =============================================================================
# DYNAMIC FLAG GENERATION
# =============================================================================

generate_flag_suffix() {
    head -c 4 /dev/urandom | xxd -p
}

INSTANCE_SUFFIX=$(generate_flag_suffix)

declare -A FLAG_BASES=(
    [0]="example"
    [1]="hidden_files"
    [2]="file_search"
    [3]="log_analysis"
    [4]="user_enum"
    [5]="perm_sleuth"
    [6]="net_detective"
    [7]="decode_master"
    [8]="ssh_secrets"
    [9]="dns_name"
    [10]="net_copy"
    [11]="web_config"
    [12]="icmp"
    [13]="cron_master"
    [14]="proc_env"
    [15]="archive_dig"
    [16]="link_follow"
    [17]="history_sleuth"
    [18]="disk_sleuth"
)

declare -A FLAGS
for i in {0..18}; do
    if [ "$i" -eq 0 ]; then
        FLAGS[$i]="CTF{example}"
    elif [ "$i" -eq 12 ]; then
        # Flag 12 must be <=16 chars for ping -p (max 32 hex chars)
        SHORT_SUFFIX=$(echo "$INSTANCE_SUFFIX" | cut -c1-4)
        FLAGS[$i]="CTF{${FLAG_BASES[$i]}_${SHORT_SUFFIX}}"
    else
        FLAGS[$i]="CTF{${FLAG_BASES[$i]}_${INSTANCE_SUFFIX}}"
    fi
done

declare -A FLAG_HASHES
for i in {0..18}; do
    FLAG_HASHES[$i]=$(echo -n "${FLAGS[$i]}" | sha256sum | cut -d' ' -f1)
done

# =============================================================================
# VERIFICATION TOKEN SECRET
# =============================================================================

INSTANCE_ID=$(head -c 16 /dev/urandom | xxd -p)
MASTER_SECRET="L2C_CTF_MASTER_2024"
VERIFICATION_SECRET=$(echo -n "${MASTER_SECRET}:${INSTANCE_ID}" | sha256sum | cut -d' ' -f1)

# =============================================================================
# SYSTEM SETUP
# =============================================================================

sudo apt-get update
sudo apt-get install -y net-tools nmap tree nginx inotify-tools figlet lolcat

for f in /etc/update-motd.d/*; do
    sudo chmod -x "$f" 2>/dev/null || true
done

if ! id "ctf_user" &>/dev/null; then
    sudo useradd -m -s /bin/bash ctf_user
    echo 'ctf_user:CTFpassword123!' | sudo chpasswd
    sudo usermod -aG sudo ctf_user
fi

# shellcheck disable=SC2016
echo 'case "$TERM" in *-ghostty) export TERM=xterm-256color;; esac' | sudo tee /etc/profile.d/fix-term.sh > /dev/null
sudo chmod 644 /etc/profile.d/fix-term.sh

sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

sudo -u ctf_user mkdir -p /home/ctf_user/ctf_challenges
cd /home/ctf_user/ctf_challenges || { echo "Failed to change directory"; exit 1; }

# =============================================================================
# WRITE FLAG HASHES FILE
# =============================================================================

sudo mkdir -p /etc/ctf
cat > /tmp/ctf_hashes << HASHEOF
$(for i in {0..18}; do echo "${FLAG_HASHES[$i]}"; done)
HASHEOF
sudo mv /tmp/ctf_hashes /etc/ctf/flag_hashes
sudo chmod 644 /etc/ctf/flag_hashes

echo "$INSTANCE_ID" | sudo tee /etc/ctf/instance_id > /dev/null
echo "$VERIFICATION_SECRET" | sudo tee /etc/ctf/verification_secret > /dev/null
sudo chmod 644 /etc/ctf/instance_id /etc/ctf/verification_secret

sudo tee /usr/local/bin/verify > /dev/null << 'EOFVERIFY'
#!/bin/bash

HASH_FILE="/etc/ctf/flag_hashes"
if [ ! -f "$HASH_FILE" ]; then
    echo "Error: CTF not properly initialized. Hash file missing."
    exit 1
fi

mapfile -t ANSWER_HASHES < "$HASH_FILE"

INSTANCE_ID=$(cat /etc/ctf/instance_id 2>/dev/null || echo "")
VERIFICATION_SECRET=$(cat /etc/ctf/verification_secret 2>/dev/null || echo "")

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
    
    if [ -z "$1" ]; then
        echo "Usage: verify export <github_username>"
        echo "Example: verify export octocat"
        echo ""
        echo "⚠️  Use your GitHub username! This will be verified when you"
        echo "   submit your token at https://learntocloud.guide"
        return 1
    fi
    local github_username="$1"
    
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
    
    echo ""
    echo "============================================================" | lolcat
    echo "         LEARN TO CLOUD - CTF COMPLETION CERTIFICATE        " | lolcat
    echo "============================================================" | lolcat
    echo ""
    echo "  This certifies that GitHub user"
    echo ""
    figlet -c "$github_username" | lolcat
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
    
    cat > "$cert_file" << CERTEOF
============================================================
         LEARN TO CLOUD - CTF COMPLETION CERTIFICATE
============================================================

  This certifies that GitHub user

              $github_username

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
    echo "Certificate saved to: $cert_file"
    
    local timestamp=$(date +%s)
    local date_str=$(date +%Y-%m-%d)
    
    local payload=$(cat << JSONEOF
{"github_username":"$github_username","date":"$date_str","time":"$completion_time","challenges":18,"timestamp":$timestamp,"instance_id":"$INSTANCE_ID"}
JSONEOF
)
    
    local signature=$(echo -n "$payload" | openssl dgst -sha256 -hmac "$VERIFICATION_SECRET" | cut -d' ' -f2)
    local token_data=$(cat << TOKENEOF
{"payload":$payload,"signature":"$signature"}
TOKENEOF
)
    local token=$(echo -n "$token_data" | base64 -w 0)
    
    echo ""
    echo "============================================================" | lolcat
    echo "              🎫 COMPLETION TOKEN                             " | lolcat  
    echo "============================================================" | lolcat
    echo ""
    echo "⚠️  Save this token! You'll need it to verify your progress"
    echo "   at https://learntocloud.guide"
    echo ""
    echo "  1. Go to https://learntocloud.guide"
    echo "  2. Sign in with GitHub (as: $github_username)"
    echo "  3. Paste the token below"
    echo ""
    echo "--- BEGIN L2C CTF TOKEN ---"
    echo "$token"
    echo "--- END L2C CTF TOKEN ---"
    echo ""
    echo ""
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
        echo "  verify export <github_username> - Export certificate with your GitHub username"
        echo
        echo "Example: verify 0 CTF{example}"
        echo "         verify export octocat"
        ;;
esac
EOFVERIFY

sudo chmod +x /usr/local/bin/verify

cat > /usr/local/bin/check_setup << 'EOF'
#!/bin/bash
if [ ! -f /var/log/setup_complete ]; then
    echo "System is still being configured. Please wait..."
    exit 1
fi
EOF

chmod +x /usr/local/bin/check_setup
echo "/usr/local/bin/check_setup" >> /home/ctf_user/.profile

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

When you complete all challenges, run: verify export <your-github-username>
Save the token it generates — you'll need it to verify your
progress at https://learntocloud.guide

Good luck!
Team L2C

+==============================================+
EOFMOTD

# Challenge 1: Hidden file
echo "${FLAGS[1]}" > /home/ctf_user/ctf_challenges/.hidden_flag

# Challenge 2: File search
mkdir -p /home/ctf_user/documents/projects/backup
echo "${FLAGS[2]}" > /home/ctf_user/documents/projects/backup/secret_notes.txt

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

# Challenge 6: Service discovery
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
echo "${FLAGS[10]}" | sudo tee /etc/ctf/flag_10 > /dev/null
cat > /usr/local/bin/monitor_directory.sh << 'EOF'
#!/bin/bash
DIRECTORY="/home/ctf_user/ctf_challenges"
FLAG=$(cat /etc/ctf/flag_10)
while [ ! -f /var/log/setup_complete ]; do
    sleep 5
done
sleep 10
touch /tmp/.ctf_upload_triggered 2>/dev/null || true
chmod 666 /tmp/.ctf_upload_triggered 2>/dev/null || true
inotifywait -m -e create --format '%f' "$DIRECTORY" | while read FILE
do
    echo "A new file named $FILE has been added to $DIRECTORY. Here is your flag: $FLAG" | wall
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
echo "${FLAGS[14]}" | sudo tee /etc/ctf/flag_14 > /dev/null
cat > /usr/local/bin/ctf_secret_process.sh << 'EOF'
#!/bin/bash
export CTF_SECRET_FLAG=$(cat /etc/ctf/flag_14)
while true; do
    sleep 3600
done
EOF
sudo chmod +x /usr/local/bin/ctf_secret_process.sh

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
sudo dd if=/dev/zero of=/opt/ctf_disk.img bs=1M count=10
sudo mkfs.ext4 -L "ctf_disk" /opt/ctf_disk.img
sudo mkdir -p /mnt/ctf_disk
sudo mount -o loop /opt/ctf_disk.img /mnt/ctf_disk
echo "${FLAGS[18]}" | sudo tee /mnt/ctf_disk/.flag > /dev/null
sudo umount /mnt/ctf_disk
sudo chown -R ctf_user:ctf_user /home/ctf_user/ctf_challenges

sudo sed -i 's/#session    optional     pam_motd.so/session    optional     pam_motd.so/' /etc/pam.d/login
sudo sed -i 's/#session    optional     pam_motd.so/session    optional     pam_motd.so/' /etc/pam.d/sshd
sudo systemctl restart ssh

HOSTNAME=$(hostname)
if ! grep -qF "$HOSTNAME" /etc/hosts; then
    echo "127.0.0.1 $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi

touch /var/log/setup_complete

echo "CTF environment setup complete!"