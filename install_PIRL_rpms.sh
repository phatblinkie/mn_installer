#!/bin/bash
echo installing prereqs, say yes to any prompts
sleep 5
yum install -y yum-utils
yum-config-manager --add-repo https://repo.pirl.io/pirl.repo
yum -y install pirl-masternode-premium
/usr/bin/pirl-setup
