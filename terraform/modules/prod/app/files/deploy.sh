#!/bin/bash
sleep 60
set -e
sudo apt list --upgradable
sudo apt update
APP_DIR=${1:-$HOME}
sudo apt install -y ruby-full ruby-bundler build-essential git
echo
echo
ruby -v
bundler -v
echo
echo
git clone -b monolith https://github.com/express42/reddit.git $APP_DIR/reddit
cd $APP_DIR/reddit
bundle install
sudo mv /tmp/puma.service /etc/systemd/system/puma.service
sudo systemctl start puma
sudo systemctl enable puma
echo
echo
ps aux | grep puma
echo "--- ############## Check running Puma: ${0}"
echo
