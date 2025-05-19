#!/bin/sh

sudo apt auto-remove -y

sudo apt update
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    python3-pip \
    virtualenv \
    python3-setuptools

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo sh -c "echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bullseye stable' > /etc/apt/sources.list.d/docker.list"

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

sudo groupadd docker 2>/dev/null
sudo usermod -aG docker vagrant


cd /vagrant && sudo make
