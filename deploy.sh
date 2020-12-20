#!/bin/bash
cd ~/
sudo apt install -y git
git clone -b monolith https://github.com/express42/reddit.git
cd ~/reddit/
bundle install
sudo puma -d
ps aux | grep puma
