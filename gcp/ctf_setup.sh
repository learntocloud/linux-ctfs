#!/bin/bash

# System setup
sudo apt update
sudo apt install -y net-tools nmap tree nginx inotify-tools

# Create CTF user
sudo useradd -m -s /bin/bash ctf_user
sudo echo 'ctf_user:CTFpassword123!' | sudo chpasswd
sudo usermod -aG sudo ctf_user

# SSH configuration
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Create challenge directory
sudo -u ctf_user mkdir -p /home/ctf_user/ctf_challenges
cd /home/ctf_user/ctf_challenges

# Create verify script
cat > /usr/local/bin/verify << 'EOFVERIFY'
#!/bin/bash

ANSWER_HASHES=(
  
    "de8f29432e21f56e003c52f71297e7364cea2b750cd2582d62688e311347ff06"  
    "a48ca3386a76ea8703a6c4e5562832f95364a2dbdaf1c75faae730abd075a23e"  
    "7e5e6218d604ac7532c7403b6ab4ef41abc45628606abcdb98d6a0c42e2477cb"  
    "1bb2e87b37adb38fe53f6e71f721e3e9ff00b3f13ce582ce95d4177c3cf49be9" 
    "0063b9de97d91b65f4abe21f3a426f266fb304b2badc4a93bb80e87dca0ed6b3"  
    "938d9c97bfc6669e0623a1b6c2f32527fd5b0081c94adb1c65dacbc6cdb04f65"  
    "04a1503e15934d9442122fd8adb2af6e35c99b41f93728fed691fafe155a1f90" 
    "4e24fc31e1bd34fd49832226ce10ea6d29fbb49e14792c25a8fa32ddf5ad7df2"  
    "1605dcdc7e89239383512803f1673cb938467c2916270807e81102894ef15e91" 
    "a7c0e0dba746fb5b0068de9943cad29273c91426174b1fdf32a42dc2af253a3f"
    "98d7b6c1cfb09574f06893baccd19f86ebf805caf5a21bf2b518598384a2d3fa"
    "90b6819737a8f027df23a718d1a82210fea013d1ae3da081494e9c496e4284da"
    "a6bbbea83c12b335d890456ecca072c61bc063dee503ed67cfa750538ad4ed69"

)

check_flag() {
    challenge_num=$1
    submitted_flag=$2
    
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
    echo "Flags Found: $completed/12"
    if [ "$completed" -eq 12 ]; then
        echo "Congratulations! You've completed all challenges!"
    fi
}

case "$1" in
    "progress")
        show_progress
        ;;
    [0-9]|1[0-2])
        if [ -z "$2" ]; then
            echo "Usage: verify [challenge_number] [flag]"
            exit 1
        fi
        check_flag "$1" "$2"
        ;;
    *)
        echo "Usage:"
        echo "  verify [challenge_number] [flag] - Check a flag"
        echo "  verify progress - Show progress"
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

Welcome! Here are 12 Progressive Linux Challenges.
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
echo "CTF{finding_hidden_treasures}" > /home/ctf_user/ctf_challenges/.hidden_flag

# Challenge 2: Basic file search
mkdir -p /home/ctf_user/documents/projects/backup
echo "CTF{search_and_discover}" > /home/ctf_user/documents/projects/backup/secret_notes.txt

# Intermediate Challenges
# Challenge 3: Log analysis
sudo dd if=/dev/urandom of=/var/log/large_log_file.log bs=1M count=500
echo "CTF{size_matters_in_linux}" | sudo tee -a /var/log/large_log_file.log
sudo chown ctf_user:ctf_user /var/log/large_log_file.log

# Challenge 4: User investigation
sudo useradd -u 1002 -m flag_user
echo "CTF{user_enumeration_expert}" | sudo tee /home/flag_user/.profile
sudo chown flag_user:flag_user /home/flag_user/.profile

# Challenge 5: Permission analysis
sudo mkdir -p /opt/systems/config
echo "CTF{permission_sleuth}" | sudo tee /opt/systems/config/system.conf
sudo chmod 777 /opt/systems/config/system.conf

# Advanced Challenges
# Challenge 6: Service discovery
cat > /usr/local/bin/secret_service.sh << 'EOF'
#!/bin/bash
while true; do
    echo -e "HTTP/1.1 200 OK\n\nCTF{network_detective}" | nc -l -p 8080
done
EOF
sudo chmod +x /usr/local/bin/secret_service.sh
sudo nohup /usr/local/bin/secret_service.sh &

# Challenge 7: Encoding challenge
echo "CTF{decoding_master}" | base64 | base64 > /home/ctf_user/ctf_challenges/encoded_flag.txt

# Challenge 8: Advanced SSH setup
sudo mkdir -p /home/ctf_user/.ssh/secrets/backup
echo "CTF{ssh_security_master}" | sudo tee /home/ctf_user/.ssh/secrets/backup/.authorized_keys
sudo chown -R ctf_user:ctf_user /home/ctf_user/.ssh
sudo chmod 700 /home/ctf_user/.ssh
sudo chmod 600 /home/ctf_user/.ssh/secrets/backup/.authorized_keys

# Challenge 9: DNS troubleshooting
sudo cp /etc/resolv.conf /etc/resolv.conf.bak
sudo sed -i '/^nameserver/s/$/CTF{dns_name}/' /etc/resolv.conf

# Challenge 10: Remote upload
cat > /usr/local/bin/monitor_directory.sh << 'EOF'
#!/bin/bash
DIRECTORY="/home/ctf_user/ctf_challenges"
inotifywait -m -e create --format '%f' "$DIRECTORY" | while read FILE
do
    echo "A new file named $FILE has been added to $DIRECTORY. Here is your flag: CTF{network_copy}" | wall
done
EOF

sudo chmod +x /usr/local/bin/monitor_directory.sh
sudo nohup /usr/local/bin/monitor_directory.sh > /var/log/monitor_directory.log 2>&1 &

# Challenge 11: Web Configuration
sudo mkdir -p /var/www/html
echo '<h2 style="text-align:center;">Flag value: CTF{web_config}</h2>' | sudo tee /var/www/html/index.html
sudo sed -i 's/listen 80 default_server;/listen 8083 default_server;/' /etc/nginx/sites-available/default
sudo sed -i 's/listen \[::\]:80 default_server;/listen \[::\]:8083 default_server;/' /etc/nginx/sites-available/default

sudo systemctl restart nginx

# Challenge 12: Network traffic analysis
sudo cat > /usr/local/bin/ping_message.sh << 'EOF'
#!/bin/bash
while true; do
    ping -p 4354467b6e65745f636861747d -c 1 127.0.0.1
    sleep 1
done
EOF

sudo chmod +x /usr/local/bin/ping_message.sh
sudo nohup /usr/local/bin/ping_message.sh > /var/log/ping_message.log 2>&1 &

# Set permissions
sudo chown -R ctf_user:ctf_user /home/ctf_user/ctf_challenges

# Enable MOTD display in PAM
sudo sed -i 's/#session    optional     pam_motd.so/session    optional     pam_motd.so/' /etc/pam.d/login
sudo sed -i 's/#session    optional     pam_motd.so/session    optional     pam_motd.so/' /etc/pam.d/sshd
sudo systemctl restart ssh

# Set proper ownership for CTF user (GCP-specific)
sudo chown -R ctf_user:ctf_user /home/ctf_user

# Mark setup as complete (required for Terraform null_resource)
sudo touch /var/log/setup_complete

echo "CTF environment setup complete!"