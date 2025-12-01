#!/bin/bash

# cannot destroy 'tank': operation does not apply to pools
# use 'zfs destroy -r tank' to destroy all datasets in the pool
# use 'zpool destroy tank' to destroy the pool itself
# /dev/vdb is in use and contains a unknown filesystem.
# cannot create 'tank/cold': dataset already exists


# destroy and rebuild backup
ssh -T -o BatchMode=yes root@bks2 'zfs destroy -r -f tank'
ssh -T -o BatchMode=yes root@bks2 'zpool destroy -f tank'
ssh -T -o BatchMode=yes root@bks2 'zpool create -o ashift=12 tank /dev/vdb'
ssh -T -o BatchMode=yes root@bks2 'zfs create tank/cold'

zfs destroy -r -f tank
zpool destroy -f tank
zpool create -o ashift=12 tank /dev/vdb
zfs create tank/cold



touch /tank/A
./zsync tank bks2 tank

touch /tank/B
./zsync tank bks2 tank

touch /tank/C
./zsync tank bks2 tank

touch /tank/D
./zsync tank bks2 tank

# master is doing a rollback, becomes behind backup
zfs list -t snapshot -H -o name | grep bk_2 | xargs -I {} zfs rollback -Rrf {}

# running zsync again should rollback backup and fix the sequencing where _0 is latest
/root/zsync tank bks2 tank
zfs list -t snapshot -o name,guid,mountpoint,creation

# root@BKS2:~# zfs list -t snapshot -o name,guid,mountpoint,creation
# NAME             GUID  MOUNTPOINT  CREATION
# tank@bk_1       3860821323376564079  -           Fri Oct 31 10:43 2025
# tank@bk_0       12111836330630318893  -           Fri Oct 31 10:44 2025
# tank/cold@bk_1  10394323085265948993  -           Fri Oct 31 10:43 2025
# tank/cold@bk_0  8472455431578389920  -           Fri Oct 31 10:44 2025

