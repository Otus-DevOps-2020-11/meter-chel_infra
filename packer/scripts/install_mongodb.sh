#!/usr/bin/env bash
echo "--- MongoDB: ${0} script START"
apt list --upgradable
apt update
apt install apt-transport-https ca-certificates
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod
echo
echo
echo
systemctl status mongod --no-pager
echo "--- ############## Check running MongoDB: ${0}"
echo
echo
exit 0
