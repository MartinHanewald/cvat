#!/bin/bash

# Steps necessary for VM setup
sudo apt-get update

# There was problem in the beginning, that the SSH user did not have sudo rights
# we have to add the user to .ssh/authorized_keys2 and add an entry to sshconf
# since the authorized_keys file is overwritten by google on restart
nano .ssh/authorized_keys2
sudo nano /etc/ssh/sshd_config


# Install docker
sudo apt-get update
sudo apt-get --no-install-recommends install -y   apt-transport-https   ca-certificates   curl   gnupg-agent   software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
sudo apt-get update
sudo apt-get --no-install-recommends install -y docker-ce docker-ce-cli containerd.io
sudo groupadd docker
sudo usermod -aG docker $USER


# Install docker-compose
sudo apt-get --no-install-recommends install -y python3-pip python3-setuptools
python3 -m pip install --upgrade pip
sudo python3 -m pip install setuptools docker-compose

# Install git and clone CVAT
sudo apt-get --no-install-recommends install -y git
git clone https://github.com/opencv/cvat

# Set environment variables for SSH
export ACME_EMAIL=martin@hanewald.ai
export CVAT_HOST=tg-annotation.hanewald.ai


# Install GDrive ocamlfuse
# ref: https://openvinotoolkit.github.io/cvat/docs/administration/advanced/mounting_cloud_storages/
sudo add-apt-repository ppa:alessandro-strada/ppa
sudo apt-get update
sudo apt-get install google-drive-ocamlfuse

# Make headless authorization
google-drive-ocamlfuse -headless -label annotations -id <ID>.apps.googleusercontent.com -secret <SECRET>

# Add the line "user_allow_other" to config
sudo nano /etc/fuse.conf

# Configure  and start service
sudo nano /etc/systemd/system/google-drive-ocamlfuse.service

# [Unit]
# Description=FUSE filesystem over Google Drive
# After=network.target

# [Service]
# Environment="MOUNT_POINT=/home/martin/GDrive"
# User=martin
# Group=martin
# ExecStart=/usr/bin/google-drive-ocamlfuse -o allow_other -label annotations ${MOUNT_POINT}
# ExecStop=/bin/fusermount -u ${MOUNT_POINT}
# Restart=always
# Type=forking

# [Install]
# WantedBy=multi-user.target

# Add Team Drive id to config
sudo nano .gdrive/annotation/config
# team_drive_id=0ACDsP_iTHJ4_Uk9PVA

sudo systemctl enable google-drive-ocamlfuse.service
sudo systemctl start google-drive-ocamlfuse.service


# deploy nuctl function
nuctl deploy --project-name cvat \
--path serverless/pytorch/saic-vul/hrnet/nuclio \
--file serverless/pytorch/saic-vul/hrnet/nuclio/function-gpu.yaml \
--volume ~/cvat/serverless/common:/opt/nuclio/common \
--platform local \
--triggers '{"myHttpTrigger": {"maxWorkers": 1}}' \
--resource-limit nvidia.com/gpu=1