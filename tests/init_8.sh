#!/bin/bash

# Test 8: master is ahead
# happens when master couldn't send to backup for w/e reason (net, disk space ...)
# there is no common guid to send an incremental from
# last resort perform a full replication

# destroy and rebuild backup
ssh -T -o BatchMode=yes root@bks2 'zfs destroy -r -f tank'
ssh -T -o BatchMode=yes root@bks2 'zpool destroy -f tank'
ssh -T -o BatchMode=yes root@bks2 'zpool create -o ashift=12 tank /dev/vdb'
ssh -T -o BatchMode=yes root@bks2 'zfs create tank/cold'

zfs destroy -r -f tank
zpool destroy -f tank
zpool create -o ashift=12 tank /dev/vdb
zfs create tank/cold
# create on master and sync
touch /tank/A
./zsync tank bks2 tank
touch /tank/B
./zsync tank bks2 tank
touch /tank/C

zfs rename -r tank@bk_1 tank@bk_2
zfs rename -r tank@bk_0 tank@bk_1

# Wait 1 min for creation time to increase
echo "Waiting 60s for creation time to differ more ..."
zfs list -t all -o name,guid,mountpoint,creation
echo "#################################"
sleep 60

# Perform new snapshot on master manually to put it ahead
zfs snapshot -r tank@bk_0

# Also delete common guid from master so it forces a full
zfs destroy -r tank@bk_1
./zsync tank bks2 tank

# all snapshots should be equal after
zfs list -t snapshot -H -o name,guid > /tmp/F1
ssh -T -o BatchMode=yes root@bks2 'zfs list -t snapshot -H -o name,guid'  > /tmp/F2

res=$( diff /tmp/F1 /tmp/F2 | wc -l )

if [[ $res != 0 ]]; then
  echo "Test 8 KO (res=$res)"
  exit 1
fi

# and they are of size 2 (showing full went through)
res=$( cat /tmp/F1 /tmp/F2 | wc -l)

if [[ $res != 4 ]]; then
  echo "Test 8 KO (res=$res)"
  exit 1
fi

echo "Test 8 OK"
