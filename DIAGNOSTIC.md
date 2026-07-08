# Diagnostic LG Hom-Bot Square VR6347LV

## Symptôme
Le robot tourne en rond et passe devant sa station de charge sans s'y arrimer.

## Causes probables
- Capteurs infrarouges encrassés/HS
- Base de charge qui n'émet plus
- Pare-chocs avant légèrement grippé
- Bug du logiciel interne (Linux embarqué)

## Contexte matériel/logiciel
- Modèle : **LG Hom-Bot Square VR6347LV** (gamme "Square", châssis différent des Hom-Bot ronds classiques VR63xx/VR64xx)
- OS : Linux embarqué, accepte des scripts via clé USB au démarrage (`update.sh` à la racine, exécuté au firmware update)
- Port USB : sous le capot supérieur, derrière le petit cache plastique/caoutchouc noir (sous la charnière, au-dessus du bac)

## ⚠️ Point de vigilance important
Toute la documentation communautaire trouvée (repo GitHub `pocketbroadcast/hombot-tools`, roboter-forum.com, blog SSH-the-LG-HomBot) concerne la gamme **ronde classique** (VR64703 et similaires), avec firmware `update.axf`/`update.dat`. **Aucune confirmation que ça fonctionne tel quel sur le châssis Square (VR6347LV)** — à tester prudemment, en isolant d'abord un script minimal de diagnostic (lecture seule, aucune modification) avant d'aller plus loin.

## Décision : diagnostic seul, PAS de hack Wi-Fi
Uniquement extraction de logs via clé USB. Pas de dongle Wi-Fi, pas de SSH pour l'instant.

## Journal des essais

### Essai n°1 (08/07/2026) — échec, cause identifiée
Le robot n'a pas réagi à la clé : `update.sh` intact, aucun fichier écrit. Cause trouvée ensuite dans `pocketbroadcast/hombot-tools` : le firmware exige une **ligne-marqueur `#IS_HIT_UPDATE_SCRIPT=1`** dans le script, sinon il l'ignore silencieusement. Le script initial ne l'avait pas — corrigé depuis.

Enseignements des scripts d'exemple du repo (gamme ronde) :
- Marqueur `#IS_HIT_UPDATE_SCRIPT=1` obligatoire (ligne 2, juste après le shebang)
- Clé montée sur `/mnt/usb` (confirmé gamme ronde seulement)
- Sons de début/fin jouables via `aplay /usr/SNDDATA/SND_BLACKBOX_LOADING_START.snd` / `..._END.snd` — intégrés au script pour avoir un retour sonore
- Le README de hombot-tools recommande une **clé USB vide** ; l'essai n°1 a été fait sur une clé chargée (29 Go de données DJ). Si l'essai n°2 échoue malgré le marqueur, retenter avec une petite clé FAT32 vide avant de conclure.

### Essai n°2 (08/07/2026) — succès ✅
Avec le marqueur, le script a tourné jusqu'au bout (dump complet dans [diag/](diag/)). Enseignements :
- **Mécanisme identique à la gamme ronde** : clé montée sur `/mnt/usb`, script lancé par `/usr/etc/rc.local`, applicatif `rpmain.axf` dans `/usr/rbin`, config XML dans `/usr/rcfg`
- Système : ARM (SoC Nexell MOST2120), Linux 2.6.33-rt, rootfs squashfs **lecture seule**, données persistantes en ubifs sur `/usr` et `/usr/data`
- `/var` est un tmpfs de 512 Ko → `/var/log` ne contient rien d'utile
- `dmesg` propre : aucune erreur matérielle au boot (caméra OV7675, audio, NAND OK). Pas de RTC : les dates de fichiers sont fantaisistes, seuls les numéros de session font foi
- **Boîte noire trouvée dans `/usr/data/blackbox`** : `LastMainboardError.txt`, cartes `MAPDATA*.blk`, journaux de session `cleanlog*.bbl` (sessions 421→470)
- **Indice fort** : les cleanlogs des sessions récentes (458→470) font tous < 700 octets contre 20–60 Ko avant → les sessions avortent quasi immédiatement

### Phase 3 en cours
`update.sh` réécrit pour rapatrier `/usr/data` complet (blackbox + SLAM), `/usr/rcfg` (config) et `rc.local` → dossier `diag2/` sur la clé (~20 Mo).

## Script `update.sh`
Voir [update.sh](update.sh) à la racine du projet (version lecture/copie uniquement, aucune commande destructrice).

### Notes sur les chemins
- `/mnt/usb`, `/var/log`, `/mnt/prj_root/etc` sont des **hypothèses** basées sur la structure Linux embarqué typique de cette famille de robots — pas confirmées pour le châssis Square.
- Le premier run sert justement à découvrir l'arborescence réelle via `filesystem_tree.txt` et `mounts.txt` : à consulter en premier pour ajuster les chemins des runs suivants.

## Procédure de test
1. Formater une clé USB en FAT32
2. Placer `update.sh` à la racine (FAT32 ne stocke pas les permissions Unix — le `chmod +x` avant copie est sans effet ; le firmware lance le script via `sh`, ça suffit)
3. Robot éteint → insérer la clé → allumer → appuyer sur START
4. Attendre l'annonce vocale de fin ("here we go" puis confirmation de complétion)
5. Éteindre, retirer la clé, lire les fichiers générés sur un ordinateur

## Si le robot ne réagit pas à la clé
Pas de son "here we go" = le firmware Square attend probablement un nom de fichier ou une structure différente. Ne pas insister en modifiant le script à l'aveugle — chercher un retour spécifique "VR6347" sur roboter-forum.com d'abord.

## Prochaines étapes possibles
- Ajouter au dump les logs spécifiques SLAM/navigation si leur emplacement est identifié
- Une fois les logs récupérés, analyser dmesg + filesystem_tree pour cerner la cause réelle (capteur IR, base, pare-chocs, ou bug logiciel)
