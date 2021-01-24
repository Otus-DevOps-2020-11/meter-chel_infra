#!/usr/bin/env bash
cd /usr/local
apt list --upgradable
apt update
apt install -y git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit
bundle install
mv /tmp/puma.service /etc/systemd/system/puma.service
systemctl start puma.service
systemctl enable puma.service
ps aux | grep puma
echo "--- ############## Check running Puma: ${0}"
exit 0
