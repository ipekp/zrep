#!/bin/bash

# Test 3: is init if there are no prefix_ID snapshots in both master and backup
# then start a full replication

# destroy and rebuild backup
ssh -T -o BatchMode=yes root@bks2 'zfs destroy -r -f tank'
ssh -T -o BatchMode=yes root@bks2 'zpool destroy -f tank'
ssh -T -o BatchMode=yes root@bks2 'zpool create -o ashift=12 tank /dev/vdb'
ssh -T -o BatchMode=yes root@bks2 'zfs create tank/cold'

zfs destroy -r -f tank
zpool destroy -f tank
zpool create -o ashift=12 tank /dev/vdb
zfs create tank/cold

# create some dataset then launch zsync
touch /tank/cold/A
touch /tank/cold/B

res=$( ./zsync tank bks2 tank 2>&1 | grep "full replication" | wc -l )

if [[ $res != 1 ]]; then
  echo "Test 3 KO (res=$res)"
  exit 1
fi

echo "Test 3 OK"

