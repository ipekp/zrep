#!/bin/bash

# timestamp sur les snapshot car rename les modifie
# egaliser les ZFS avant tout (sauf si c un init)
# fonction qui egalise
# opt refactor un peu (fonction send_init, fonction equalize, fonction rolling)

keep=3

prefix=$(date +%Y%m%d_%H%M%S) #la date de creation du snap est dessus
prefix="bk"

# si snap 0 n'existe pas c un init

is_init=$(zfs list -t snapshot 2>&1 | grep -E '_0 ' | wc -l)
if [[ $is_init == 0 ]]; then 
    echo "sending init ..."
    zfs snapshot tank@${prefix}_0
    zfs send -R tank@${prefix}_0 | ssh -T bks2 zfs recv -F tank
    exit 0
fi

# efface toujours la derniere
echo "zfs destroy -r tank@${prefix}_$keep" 
zfs destroy -r tank@${prefix}_$keep > /dev/null 2>&1
# rename tout le reste +1
for ((i=$keep-1; i>=0; i--)); do
    echo "zfs rename tank@${prefix}_$i tank@${prefix}_$((i+1))"
    zfs rename tank@${prefix}_$i tank@${prefix}_$((i+1)) > /dev/null 2>&1
done
# prend ton snap day 0 et envoie
echo "zfs snapshot tank@${prefix}_0"
zfs snapshot tank@${prefix}_0
echo "zfs send -R -I tank@${prefix}_1 tank@${prefix}_0 | ssh -T bks2 zfs recv -F tank"
zfs send -R -I tank@${prefix}_1 tank@${prefix}_0 | ssh -T bks2 zfs recv -F tank
