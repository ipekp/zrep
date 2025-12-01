#!/bin/bash

DIR="/root"
TSTDIR="$DIR/tests"

cd $DIR

#ssh -T -o BatchMode=yes root@bks2 'zfs destroy -r -f tank'

# Test 2: if master and backup are out of sync more than 100s exit 1

curr=$(date +%s)
curr1k=$(( $curr - 1000 ))

prev_date=$(date -d "@$curr"  '+%a %b %d %H:%M:%S %Z %Y')
change_date=$(date -d "@$curr1k"  '+%a %b %d %H:%M:%S %Z %Y')

# reduce local time by 1000s and test
timedatectl set-ntp false
date --set="$change_date"

./zsync tank bks2 tank
res1=$?
res2=$(./zsync tank bks2 tank 2>&1 | grep "out of time sync" | wc -l)

res=$(( res1 + res2 ))
if [[ $res != 2 ]]; then
  echo "Test 2 KO (res=$res)"
  exit 1
fi

## rollback local time
#date --set="$prev_date"
timedatectl set-ntp true

echo "Test 2 OK"

# reduce remote time by 1000s and test @TODO
#ssh -T -o BatchMode=yes root@bks2 'zfs destroy -r -f tank'
