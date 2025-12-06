#!/bin/bash

# Test 5: master is behind, for ex master rolled back a a previous stable FS
# but the backup remains ahead or in w/e state
# option1 is the find the common GUID to stabilize on
# and if it doesn't exist then reset snaps and do full


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
./zsync tank bks2 tank
touch /tank/D
./zsync tank bks2 tank

# Rollback master to bk_2
zfs list -t snapshot -H -o name | grep bk_2 | xargs -I {} zfs rollback -Rrf {}

# master is behind bc of rollback but common GUID should exist, launch equalize
./zsync tank bks2 tank

# all snapshots should be equal after
zfs list -t snapshot -H -o name,guid > /tmp/F1
ssh -T -o BatchMode=yes root@bks2 'zfs list -t snapshot -H -o name,guid'  > /tmp/F2

res=$( diff /tmp/F1 /tmp/F2 | wc -l )

if [[ $res != 0 ]]; then
  echo "Test 5 KO (res=$res)"
  exit 1
fi

echo "Test 5 OK"

