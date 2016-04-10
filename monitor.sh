#!/bin/bash

VERSION="0.0.1"
LOGFILE="/tmp/$LOGNAME_`date +%s`.hash"
TYPESFILE="$LOGFILE.types"
SLEEP=1

if [ -n "$1" ]; then
  if [ $1 == "-h" -o $1 == "--help" ]; then
    cat << EOF
Script that monitors a directory for any change

Usage: ./monitor.sh [option] directory [sleep]

Options:
  -h, --help      prints this message
  -v, --version   prints version
  sleep           delay time for checking the provided directory
EOF
    exit 2
  elif [ $1 == "-v" -o $1 == "--version" ]; then
    echo $VERSION

    exit 2
  elif [ ! -d $1 ]; then
    echo Parameter should be a directory name
    exit 2
  fi
else
    echo Please give a directory as parameter
    exit 2
fi

if [ -n "$2" ]; then
  if ! [[ "$2" =~ ^[0-9]+$ ]] ; then
    echo The sleep time should be a number
    exit 2
  fi
  SLEEP=$2
fi

function exit_process() {
  echo Exiting!

  if [ -e $LOGFILE ]; then
    rm $LOGFILE
  fi
  
  if [ -e $TYPESFILE ]; then
    rm $TYPESFILE
  fi

  for job in $(jobs -p); do
    kill $job
  done

  exit 0
}

function add() {
  find $1 > $LOGFILE.add

  while true; do
    find $1 > $LOGFILE.add.tmp

    while IFS='' read -r path || [[ -n "$path" ]]; do
      if ! grep -qxF "$path" $LOGFILE.add; then
        if [ -f $path ]; then
          echo New file: $path
        else
          echo New directory: $path
        fi
      fi
    done < $LOGFILE.add.tmp
   
    if [ -e $LOGFILE.add.tmp ]; then
      mv $LOGFILE.add.tmp $LOGFILE.add
    fi

    sleep $SLEEP
  done
}

function remove() {
  find $1 > $LOGFILE.remove
  find $1 -exec file -b {} \; > $TYPESFILE

  while true; do
    find $1 > $LOGFILE.remove.tmp
    find $1 -exec file -b {} \; > $TYPESFILE.tmp

    while IFS='' read -r path || [[ -n "$path" ]]; do
      if ! grep -qxF "$path" $LOGFILE.remove.tmp; then

        line="`grep -nF -m 1 "$path" $LOGFILE.remove | cut -d : -f 1`p"

        filetype=$(sed -n "$line" $TYPESFILE)

        if [ "$filetype" == "directory" ]; then
          echo Removed directory: $path
        else
          echo Removed file: $path
        fi
      fi
    done < $LOGFILE.remove
   
    if [ -e $LOGFILE.remove.tmp ]; then
      mv $LOGFILE.remove.tmp $LOGFILE.remove
    fi

    if [ -e $TYPESFILE.tmp ]; then
      mv $TYPESFILE.tmp $TYPESFILE
    fi

    sleep $SLEEP
  done
}

trap "exit_process" SIGINT SIGTERM

echo Running

add $1 &
remove $1 &

for job in $(jobs -p); do
  wait $job
done
