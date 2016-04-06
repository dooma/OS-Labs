#!/bin/bash

VERSION="0.0.1"
LOGFILE="/tmp/$LOGNAME_`date +%s`.hash"
if [ -f "`which md5`" ]; then
  MD5="`which md5`"
elif [ -f "`which md5sum`" ]; then
  MD5="`which md5sum`"
else
  echo MD5 is mandatory. Exiting...
  sleep 1
  
  exit 2
fi

if [ -n "$1" ]; then
  if [ $1 == "-h" -o $1 == "--help" ]; then
    cat << EOF
Script that monitors a directory for any change

Usage: ./monitor.sh [option] directory

Options:
  -h, --help  prints this message
  -v, --version prints version
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

function exit_process() {
  echo Exiting!
  
  rm $LOGFILE

  exit 1
}

trap "exit_process" SIGINT SIGTERM

echo Running

find $1 > $LOGFILE
find $1 -exec file -b {} \; > $LOGFILE.types

while true; do
  STATUS=`find $1`
  TYPES=`find $1 -exec file -b {} \;`

  for $path in $STATUS; do
    if ! grep -qxF "$path" $LOGFILE; then
      if [ -f $path ]; then
        echo New directory: $path
      else
        echo New file: $path
      fi
    fi

    echo $path >> $LOGFILE.tmp
  done

  #for path in `cat $LOGFILE`; do
  #  if ! grep -qxF "$path" $LOGFILE.tmp; then
  #    if [ -f $path ]; then
  #      echo Removed file: $path
  #    else
  #      echo Removed directory: $path
  #    fi
  #  fi
  #done
 
  mv $LOGFILE.tmp $LOGFILE

  sleep 2
done
