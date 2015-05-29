#!/bin/bash

# Get Last Login IP
IP="$(last -w -d -i -1 | grep "darwin " | cut -d" " -f12-13 | cut -d"." -f4)"

HOST=$(hostname)

#if [ $IP == "201" ]; then
#  NAME="Yida"
#  EMAIL="yida@seas.upenn.edu"
#elif [ $IP == "202" ]; then
#  NAME="SJ"
#  EMAIL="seungjoon.yi@gmail.com"
#elif [ $IP == "203" ]; then
#  NAME="Larry"
#  EMAIL="larryabraham@gmail.com"
#elif [ $IP == "204" ]; then
#  NAME="Aditya"
#  EMAIL="aditya.sreekumar@gmail.com"
#elif [ $IP == "205" ]; then
#  NAME="Stephen"
#  EMAIL="smcgill3@seas.upenn.edu"
#else
#  NAME="unknown"
#fi

# git config --global --unset user.name
# git config --global --unset user.email

#if [ $NAME == "unknown" ]; then
#  echo "Please Name Yourself For Git:"
#  echo "  git config --global user.name Your Name"
#  echo "  git config --global user.email your email"
#else
#  echo "Welcome $NAME"
#  echo "GIT user and email has been set for you"
#  git config --global user.name "$NAME@$HOST"
#  git config --global user.email "$EMAIL"
#fi
