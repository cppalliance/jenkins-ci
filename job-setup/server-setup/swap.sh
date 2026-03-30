#!/bin/bash
set -x
cd /
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

#To make the change permanent open the /etc/fstab file:
#sudo vi /etc/fstab
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
