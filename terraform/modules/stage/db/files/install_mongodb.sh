#!/usr/bin/env bash
echo
echo
echo "--- ##########  MongoDB: ${0} script START ####"
echo
echo
sleep 60
set -e
sudo apt list --upgradable
sudo apt update
#sudo apt install apt-transport-https ca-certificates
sudo apt install -y apt-transport-https ca-certificates gnupg libssl-dev
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
echo
echo
sudo systemctl status mongod --no-pager
echo "--- ############## Check running MongoDB: ${0}"
echo
exit 0
