#!/usr/bin/env bash
apt list --upgradable
apt update
apt install -y ruby-full ruby-bundler build-essential git
ruby -v
bundler -v
echo "-------################  Check Ruby fnd Bundler install : ${0} "
exit 0
