#!/bin/bash
# Author: Eddie Lu
# Description: Bash script to automate set up Cloudfared DoH for Pi-hole on Raspbian
# Reference:
# https://docs.pi-hole.net/guides/dns-over-https/
# https://www.cyberciti.biz/faq/configure-ubuntu-pi-hole-for-cloudflare-dns-over-https/

# 1. download the precompiled binary and copy it to the /usr/local/bin/ directory

wget https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-arm.tgz
tar -xvzf cloudflared-stable-linux-arm.tgz
sudo cp ./cloudflared /usr/local/bin
sudo chmod +x /usr/local/bin/cloudflared
cloudflared -v

# 2. configure cloudflared to run on startup
sudo useradd -s /usr/sbin/nologin -r -M cloudflared

# lock down the cloudflared user
sudo passwd -l cloudflared
sudo chage -E 0 cloudflared

cat > /etc/default/cloudflared <<'EOM'
# Commandline args for cloudflared
CLOUDFLARED_OPTS=--port 5053 --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query

EOM

sudo chown cloudflared:cloudflared /etc/default/cloudflared
sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared

cat > /etc/systemd/system/cloudflared.service <<'EOM'
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=syslog.target network-online.target

[Service]
Type=simple
User=cloudflared
EnvironmentFile=/etc/default/cloudflared
ExecStart=/usr/local/bin/cloudflared proxy-dns $CLOUDFLARED_OPTS
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target

EOM

sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared

# 3. verify
dig @127.0.0.1 -p 5053 www.google.com

# 4. configure Pi-hole to use Custom Upstream DNS Server 127.0.0.1#5053
echo "Logon http://<pihole.ip.address>/admin"
echo "Setting, DNS, Upstream DNS Servers"
echo "Custom 1 (IPv4): 127.0.0.1#5053"
