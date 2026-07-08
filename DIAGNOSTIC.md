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

### Essai n°3 (08/07/2026) — blackbox récupérée, cause identifiée ✅

Dump complet dans [diag2/](diag2/) (cartes, SLAM, trajectoires et n° de série exclus du repo public via `.gitignore`). Les `cleanlog*.bbl` sont du **CSV texte lisible** : un événement horodaté par ligne.

**Verdict : le robot ne reçoit aucun signal infrarouge de la base.**

Preuves, par ordre d'importance :
1. **Session 460** : en phase homing, le robot logge `POSI,DockNoSinal, 527, -252, ...` puis termine par `End Cleaning (Not Docking)`. Les sessions qui démarrent arrimées montrent la base vers (550, 50) : le robot était donc à ~30 cm de la base **sans capter son faisceau**.
2. **La vision/SLAM fonctionne** dans les sessions récentes (`VC_MAP_ROT_READY` présent en 459, 460, 467, 469) : la caméra plafond localise bien le robot, qui *navigue* correctement jusqu'à la zone de la base. Le guidage terminal IR est le seul maillon mort.
3. `cleaningrecord.stc` : 5 nettoyages démarrés / 0 terminés depuis le dernier reset des stats, 1 kidnap avec échec de récupération.
4. Historique ancien sain : 26 sessions terminées `(Docked)` — le mécanisme d'arrimage fonctionnait.

Éléments secondaires :
- `LastMainboardError.txt` : « Vision board was reset » — mais horodaté à l'époque de la session 427 (milieu d'historique), et la vision marche dans les sessions récentes → **pas la cause actuelle**.
- 2 arrêts d'urgence récents `Wheeldrop Motion Fail` (sessions 466, 469) : capteur de roue pendante déclenché en roulant — soit robot soulevé pendant les tests, soit interrupteurs de roues encrassés. À surveiller, mais distinct du problème d'arrimage.
- Sessions 459 et 461 : logs tronqués sans ligne de fin (coupure d'alimentation ou crash applicatif).
- Firmware rev. 16552 (2015/11/12), bootloader 201, modèle n° 1762.

**Prochaines vérifications physiques (dans l'ordre) :**
1. La base est-elle alimentée ? (LED allumée, prise testée)
2. **Test caméra de smartphone** face à la fenêtre avant de la base (caméra frontale de préférence, pas de filtre IR) : les émetteurs IR doivent apparaître comme des points lumineux violacés. Absents → la base n'émet plus (panne base/alim) → réparer ou remplacer la base.
3. Si la base émet : nettoyer soigneusement les fenêtres IR du robot (bandeau du pare-chocs avant) à l'alcool isopropylique. Retester le homing.
4. Toujours en échec → récepteurs IR du robot HS (carte capteurs du pare-chocs à inspecter).
5. Au passage : nettoyer les roues latérales et vérifier le débattement de leurs interrupteurs (cause des `Wheeldrop Motion Fail`).

### Conclusion (08/07/2026) — panne confirmée : la base n'émet plus d'IR ✅

Test caméra validé par contrôle : la caméra frontale du téléphone voit l'IR d'une télécommande TV (points violacés), mais **rien au niveau de la fenêtre avant de la base**, y compris pendant un homing. (La caméra arrière filtre l'IR — premier test non probant.)

Précision importante : le robot **charge** quand on le pose manuellement sur la base (sessions `Begin (Docked)`, batterie High dans les cleanlogs) → la base est alimentée. C'est donc la **carte d'émission IR de la base** qui est HS (LED émettrices ou soudures), pas son alimentation. Cohérent à 100 % avec le `DockNoSinal` de la blackbox et le symptôme initial.

**Options de réparation :**
1. Ouvrir la base (vis sous le socle) : inspection des LED IR et de leurs soudures (soudures sèches fréquentes). Une LED IR se teste au multimètre en polarisation directe, ou à la caméra frontale une fois alimentée. Réparation à quelques euros si LED/soudure en cause.
2. Remplacer la base : pièce détachée « support/base de charge » pour VR6347LV (SAV LG, sites de pièces détachées, ou base d'occasion compatible gamme Square sur eBay/Leboncoin).

En attendant : le robot reste utilisable en le posant manuellement sur la base pour la charge.

### Bonus découverts dans `rc.local` (mécanismes officiels du firmware)
- Un dossier `blackbox/` à la racine de la clé déclenche `/usr/rscript/blackbox.sh` (export officiel de la boîte noire)
- Un dossier `debug/` sur la clé active les core dumps vers la clé
- Un `update.dat` à la racine est traité par `update.axf` (mise à jour firmware officielle)
- Si un dongle Wi-Fi est détecté au boot, `dropbear` (serveur SSH) est lancé — confirme que le hack Wi-Fi de la gamme ronde s'applique tel quel au Square

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
