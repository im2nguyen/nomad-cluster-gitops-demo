#!/bin/bash

## This script is used by Packer to generate the AMI
## It installs prepequisites and the HashiStack tools

set -e

# Disable interactive apt prompts
export DEBIAN_FRONTEND="noninteractive"

pushd /ops

# CONFIGDIR=/ops/shared/config
CONFIGDIR=/ops/shared/conf

CONSULVERSION=1.19.0
ENVOYVERSION=1.29.x
VAULTVERSION=1.17.3
NOMADVERSION=1.8.3
CONSULTEMPLATEVERSION=0.39.1

CONSULTEMPLATECONFIGDIR=/etc/consul-template.d
CONSULTEMPLATEDIR=/opt/consul-template

sudo apt-get clean
sudo apt-get install -y software-properties-common gnupg

sudo add-apt-repository universe

# Java repo
sudo add-apt-repository -y ppa:openjdk-r/ppa

# Docker repo
distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${distro} $(lsb_release -cs) stable"

# HashiCorp repo
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y unzip tree redis-tools jq curl tmux apt-transport-https ca-certificates openjdk-8-jdk docker-ce consul=$CONSULVERSION* nomad=$NOMADVERSION* vault=$VAULTVERSION* consul-template=$CONSULTEMPLATEVERSION*



# Disable the firewall
sudo ufw disable || echo "ufw not installed"

## Configure
sudo mkdir -p $CONSULTEMPLATECONFIGDIR
sudo chmod 755 $CONSULTEMPLATECONFIGDIR
sudo mkdir -p $CONSULTEMPLATEDIR
sudo chmod 755 $CONSULTEMPLATEDIR

# Setup Java
JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

popd