#!/bin/bash
CWD=`pwd`
USAGE="./install_nao.sh <path/to/usb/root/partition> <path/to/usb/user/partition>"

# check args
if [ $# -ne 2 ]; then
  echo "usage:"
  echo "$USAGE"
  exit
fi

# create /usr/local/ folder in home
sudo mkdir -p $2/local/
sudo rsync -avr --exclude=".*" dependencies/usr/local/* $2/local/
sudo chown -R 1001 $2/local/
sudo chgrp -R 18 $2/local/

# sync etc dependencies to the nao root
sudo rsync -avr --exclude=".*" dependencies/etc/* $1/etc/
# sync usr dependencies to the nao root
sudo rsync -avr --exclude=".*" --exclude="local" dependencies/usr/* $1/usr/

# link /home/local to /usr/local
sudo ln -s /home/local/ $1/usr/local

# install matlab -- optional
#read -p "copy matlab? (y/n): "
#if [ $REPLY == "y" ]; then
#  read -p "local matlab dir: "
#  sudo mkdir -p $2/local/matlab
#  sudo rsync -avr $REPLY/* $2/local/matlab/
#fi

# remove aldebaran startups?
read -p "remove aldebaran connman startup (recommended)? (y/n): "
if [ $REPLY == "y" ]; then
  sudo rm -f $1/etc/rc5.d/S15connman
fi
read -p "remove aldebaran naopathe startup (recommended)? (y/n): "
if [ $REPLY == "y" ]; then
  sudo rm -f $1/etc/rc5.d/S50naopathe
fi
