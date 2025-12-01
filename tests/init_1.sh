#!/bin/bash

DIR="/root"
TSTDIR="$DIR/tests"

cd $DIR

#ssh -T -o BatchMode=yes root@bks2 'zfs destroy -r -f tank'

# Test 1: if there's no reach to backup, master zsync should stop and warn

# chg bks2 host ip to simulate reach loss
sed 's/205/199/' -i /etc/hosts

./zsync tank bks2 tank

if [[ $? -ne 1 ]]; then
  echo "Test 1 KO"
  exit 1
fi

echo "Test 1 OK"

# restore bks2 ip to prev
sed 's/199/205/' -i /etc/hosts

