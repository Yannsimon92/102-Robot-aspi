#!/bin/sh
#IS_HIT_UPDATE_SCRIPT=1
# ^ Ligne-marqueur obligatoire : le firmware Hom-Bot refuse d'exécuter un
#   update.sh qui ne la contient pas (cf. pocketbroadcast/hombot-tools).
# Diagnostic LG Hom-Bot Square VR6347LV — PHASE 2 : dump de la blackbox.
# Lecture/copie uniquement. A placer à la racine d'une clé USB FAT32.

# Son de démarrage : confirme à l'oreille que le script tourne
aplay -c 1 -r 16000 -f S16_LE /usr/SNDDATA/SND_BLACKBOX_LOADING_START.snd 2>/dev/null

# Clé montée sur /mnt/usb (confirmé au run n°2 sur le VR6347LV) ;
# on garde le repli sur le dossier du script par prudence.
USB_PATH="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
[ -n "$USB_PATH" ] && [ -w "$USB_PATH" ] || USB_PATH="/mnt/usb"
OUT="$USB_PATH/diag2"
mkdir -p "$OUT"

date > "$OUT/diag_timestamp.txt"

# La cible principale : boîte noire (erreur carte mère, cleanlogs .bbl,
# cartes MAPDATA .blk), données SLAM et fichiers d'état.
mkdir -p "$OUT/usr_data"
cp -r /usr/data/* "$OUT/usr_data/" 2>"$OUT/copy_errors.txt"

# Toute la config applicative (SLAM.xml + .bak, Navi.xml, BlackBox.xml, ...)
mkdir -p "$OUT/rcfg"
cp -r /usr/rcfg/* "$OUT/rcfg/" 2>>"$OUT/copy_errors.txt"

# rc.local : pour comprendre le mécanisme update.sh et les options du firmware
cp /usr/etc/rc.local "$OUT/rc.local.txt" 2>>"$OUT/copy_errors.txt"

# dmesg de ce boot (comparaison avec le run n°2)
dmesg > "$OUT/dmesg.txt" 2>&1

date > "$OUT/diag_done.txt"

# Indispensable : forcer l'écriture physique sur la clé avant l'arrêt du robot
sync
sync

# Son de fin : confirme que le script est allé au bout
aplay -c 1 -r 16000 -f S16_LE /usr/SNDDATA/SND_BLACKBOX_LOADING_END.snd 2>/dev/null

exit 0
