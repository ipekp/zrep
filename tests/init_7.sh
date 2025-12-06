#!/bin/bash

# Test 7: master is ahead
# happens when master couldn't send to backup for w/e reason (net, disk space ...)
# option1 is to find a starting point


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

# common guid should be found and an incremental should be sent
./zsync tank bks2 tank

# all snapshots should be equal after
zfs list -t snapshot -H -o name,guid > /tmp/F1
ssh -T -o BatchMode=yes root@bks2 'zfs list -t snapshot -H -o name,guid'  > /tmp/F2

res=$( diff /tmp/F1 /tmp/F2 | wc -l )

if [[ $res != 0 ]]; then
  echo "Test 7 KO (res=$res)"
  exit 1
fi

echo "Test 7 OK"

