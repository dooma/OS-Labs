#!/bin/bash

VERSION="0.0.1"

if [ -n "$1" ]; then
  if [ $1 == "-h" -o $1 == "--help" ]; then
    cat << EOF
Script that monitors a directory for any change

Usage: ./words.sh [option]

Options:
  -h, --help      prints this message
  -v, --version   prints version
EOF
    exit 2
  elif [ $1 == "-v" -o $1 == "--version" ]; then
    echo $VERSION

    exit 2
  fi
fi

while read -p "Give a text file name and a number: " file number ; do
  if [ ! -f $file ] || [ $(! file $file | grep -qF "ASCII text") ]; then
    echo !!! First parameter should be a text file !!!
    continue
  fi

  if ! [[ "$number" =~ ^[0-9]+$ ]]; then
    echo !!! Second parameter should be a number !!!
    continue
  fi

  words=`cat $file | cut -d' ' -f $number`

  for word in $words; do
    echo $file - $number: $word
  done
done
