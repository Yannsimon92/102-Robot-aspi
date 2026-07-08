#!/bin/sh
# Diagnostic LG Hom-Bot Square VR6347LV — lecture/copie uniquement.
# A placer à la racine d'une clé USB FAT32.

# Le point de montage de la clé n'est pas confirmé sur le châssis Square :
# on écrit dans le dossier qui contient ce script, où qu'il soit monté.
USB_PATH="$(cd "$(dirname "$0")" && pwd)"
OUT="$USB_PATH/diag"
mkdir -p "$OUT"

# Preuve d'exécution immédiate (si ce fichier existe, le script a tourné)
date > "$OUT/diag_timestamp.txt"

# Points de montage réels — à lire en premier pour ajuster les chemins
mount > "$OUT/mounts.txt" 2>&1
cat /proc/mounts >> "$OUT/mounts.txt" 2>&1
cat /proc/partitions > "$OUT/partitions.txt" 2>&1

# Identité du système
uname -a > "$OUT/uname.txt" 2>&1
cat /proc/version >> "$OUT/uname.txt" 2>&1
cat /proc/cpuinfo > "$OUT/cpuinfo.txt" 2>&1
ps > "$OUT/ps.txt" 2>&1

# Vue d'ensemble du système de fichiers.
# On évite /proc, /sys et /dev : les parcourir en récursif produit un fichier
# énorme et peut bloquer sur certains pseudo-fichiers. On évite aussi la clé
# elle-même. On liste donc chaque répertoire racine réel individuellement.
for d in /bin /sbin /etc /lib /usr /var /opt /home /root /tmp /mnt /data /app /oem; do
    [ -d "$d" ] && ls -Rl "$d" >> "$OUT/filesystem_tree.txt" 2>&1
done
ls -l / > "$OUT/root_listing.txt" 2>&1

# Logs système classiques
mkdir -p "$OUT/var_log" "$OUT/tmp_logs"
cp -r /var/log/* "$OUT/var_log/" 2>/dev/null
cp /tmp/*.log "$OUT/tmp_logs/" 2>/dev/null

# Logs noyau (utile pour erreurs capteurs/moteurs)
dmesg > "$OUT/dmesg.txt" 2>&1

# Config / état si présents
mkdir -p "$OUT/etc_config"
cp -r /mnt/prj_root/etc/* "$OUT/etc_config/" 2>/dev/null

# Marqueur de fin : si ce fichier existe, le script est allé au bout
date > "$OUT/diag_done.txt"

# Indispensable : forcer l'écriture physique sur la clé avant l'arrêt du robot,
# sinon les fichiers peuvent être vides ou absents au retrait de la clé.
sync
sync

exit 0
