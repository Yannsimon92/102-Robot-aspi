# Diagnostic LG Hom-Bot Square VR6347LV

Diagnostic et réparation, **réussie**, d'un **LG Hom-Bot Square VR6347LV** qui ne s'arrimait plus à sa base et tournait en rond au lieu de nettoyer. Le diagnostic a été mené **sans démontage et sans modification du robot** : uniquement par extraction de logs via clé USB, en exploitant le mécanisme `update.sh` du firmware — un vrai démontage n'a eu lieu qu'une fois la roue gauche formellement désignée comme coupable.

La documentation communautaire existante sur ce mécanisme (`pocketbroadcast/hombot-tools`, roboter-forum) ne couvrait que la gamme ronde VR63xx/VR64xx. Ce dépôt confirme qu'il est **identique** sur le châssis Square (VR6347LV), point qui n'était pas documenté publiquement avant.

## Résultat — ✅ résolu

**Une seule panne réelle** : un fil du faisceau moteur/encodeur de la roue gauche, sectionné par usure mécanique après ~216h d'usage — le fil bleu formait un coude à 180° juste au-dessus du ressort de suspension de la roue, et le mouvement répété de haut en bas du ressort a fini par le sectionner à ce point de pliure. Repéré par l'œil avisé de mon papa, en réanalysant les photos de démontage, puis ressoudé par ses soins <3. Le symptôme « base introuvable » (`DockNoSinal` dans la blackbox) n'était qu'une conséquence : le robot ne pouvait pas s'aligner sur le faisceau IR sans sa roue gauche — la base elle-même n'a jamais été en cause.

| Panne | Preuve | Résultat |
|---|---|---|
| Le **module de roue gauche ne motrice plus** (le robot pivote sur place au lieu de nettoyer) | Pilotage manuel à la télécommande : gauche OK, droite KO, dérive à gauche en marche avant ; log de session vide (jamais de phase de nettoyage, pare-chocs muet) | ✅ **Résolu** — fil sectionné à un coude, ressoudé, gaine thermorétractable, fil reroutée à l'écart du ressort de suspension |
| L'**arrimage à la base échouait** (`DockNoSinal` : aucun signal IR reçu à ~30 cm de la base) | Blackbox + chronologie montrant que tout cassait dans la même fenêtre de sessions (457→460) | ✅ **Résolu par la même réparation** — le robot s'arrime de nouveau tout seul |

## Contenu du dépôt

| Fichier / dossier | Rôle |
|---|---|
| [update.sh](update.sh) | Script de dump à copier à la racine d'une clé USB FAT32. Lecture/copie uniquement. Copie blackbox, config et logs vers la clé. |
| [diag/](diag/) | Dump n°1 : identité système, points de montage, `dmesg`, arborescence complète du robot. |
| [diag2/](diag2/) | Dump n°2 : `rc.local`, config applicative (`/usr/rcfg`), erreur carte mère, statistiques. Les données privées (cartes du logement, SLAM, trajectoires, n° de série) sont exclues du dépôt via `.gitignore`. |

## Contexte matériel/logiciel

- Modèle : **LG Hom-Bot Square VR6347LV** (gamme "Square", châssis différent des Hom-Bot ronds classiques VR63xx/VR64xx)
- OS : Linux embarqué, accepte des scripts via clé USB au démarrage (`update.sh` à la racine, exécuté au firmware update)
- Port USB : sous le capot supérieur, derrière le petit cache plastique/caoutchouc noir (sous la charnière, au-dessus du bac)
- Système embarqué : SoC Nexell MOST2120 (ARMv6), Linux 2.6.33-rt PREEMPT_RT, rootfs squashfs lecture seule, données persistantes en UBIFS sur `/usr` et `/usr/data`, busybox. Firmware rev. 16552 (2015), caméra plafond OV7675 pour le VSLAM. Carte mère LG EBR8146.

**Choix méthodologique** : diagnostic uniquement par extraction de logs via clé USB. Pas de dongle Wi-Fi, pas de SSH, aucune modification du robot avant d'avoir une cause certaine.

## Ce qu'il faut savoir sur le mécanisme `update.sh` (châssis Square)

Toute la documentation communautaire trouvée avant ce projet (repo GitHub `pocketbroadcast/hombot-tools`, roboter-forum.com, blog SSH-the-LG-HomBot) concernait la gamme **ronde classique** (VR64703 et similaires), avec firmware `update.axf`/`update.dat`. Aucune confirmation que ça fonctionnait tel quel sur le châssis Square — c'était le premier risque à lever, en isolant d'abord un script minimal de diagnostic (lecture seule, aucune modification).

Ce qui est maintenant confirmé sur le VR6347LV :

- Le script doit contenir la ligne-marqueur **`#IS_HIT_UPDATE_SCRIPT=1`**, sinon le firmware l'ignore silencieusement (premier essai raté à cause de cet oubli)
- La clé (FAT32) est montée sur `/mnt/usb` ; le script est lancé en root par `/usr/etc/rc.local` au démarrage
- Fins de ligne **Unix (LF)** obligatoires — ne pas éditer le script sous Windows/Notepad ; FAT32 ne stocke pas les permissions Unix, donc `chmod +x` avant copie est sans effet
- Sons de début/fin jouables via `aplay /usr/SNDDATA/SND_BLACKBOX_LOADING_START.snd` / `..._END.snd` — utile comme confirmation sonore que le script tourne
- Les journaux de session `cleanlog*.bbl` de la blackbox (`/usr/data/blackbox`) sont du **CSV texte lisible** : un événement horodaté par ligne
- Bonus trouvés dans `rc.local` : un dossier `blackbox/` sur la clé déclenche un export officiel de la boîte noire ; un dossier `debug/` active les core dumps ; un `update.dat` à la racine est traité par `update.axf` (mise à jour firmware officielle) ; un dongle Wi-Fi au boot lance `dropbear` (serveur SSH) — le hack Wi-Fi de la gamme ronde s'applique donc tel quel au Square

**Procédure de test :**
1. Formater une clé USB en FAT32, placer `update.sh` à sa racine
2. Robot éteint → insérer la clé → allumer → appuyer sur START
3. Attendre l'annonce vocale de fin ("here we go" puis confirmation de complétion)
4. Éteindre, retirer la clé, lire les fichiers générés sur un ordinateur

Si pas de son "here we go" : le firmware Square attend peut-être un nom de fichier ou une structure différente — ne pas modifier le script à l'aveugle, chercher d'abord un retour spécifique "VR6347" sur roboter-forum.com.

## Journal du diagnostic

### Essai n°1 — échec, cause identifiée
Le robot n'a pas réagi à la clé : `update.sh` intact, aucun fichier écrit. Cause trouvée dans `pocketbroadcast/hombot-tools` : la ligne-marqueur `#IS_HIT_UPDATE_SCRIPT=1` manquait dans le script initial.

### Essai n°2 — succès ✅
Avec le marqueur, le script a tourné jusqu'au bout (dump complet dans [diag/](diag/)).
- **Mécanisme identique à la gamme ronde** : clé montée sur `/mnt/usb`, script lancé par `/usr/etc/rc.local`, applicatif `rpmain.axf` dans `/usr/rbin`, config XML dans `/usr/rcfg`
- `/var` est un tmpfs de 512 Ko → `/var/log` ne contient rien d'utile
- `dmesg` propre : aucune erreur matérielle au boot. Pas de RTC : les dates de fichiers sont fantaisistes, seuls les numéros de session font foi
- **Boîte noire trouvée dans `/usr/data/blackbox`** : `LastMainboardError.txt`, cartes `MAPDATA*.blk`, journaux de session `cleanlog*.bbl` (sessions 421→470)
- **Indice fort** : les cleanlogs des sessions récentes (458→470) font tous < 700 octets contre 20–60 Ko avant → les sessions avortent quasi immédiatement

### Essai n°3 — blackbox récupérée, premier verdict (base) ✅⚠️

Dump complet dans [diag2/](diag2/). Preuves, par ordre d'importance :
1. **Session 460** : en phase homing, le robot logge `POSI,DockNoSinal, 527, -252, ...` puis termine par `End Cleaning (Not Docking)`, à ~30 cm de la position connue de la base **sans capter son faisceau**
2. **La vision/SLAM fonctionne** dans les sessions récentes (`VC_MAP_ROT_READY` présent en 459, 460, 467, 469) : la caméra plafond localise bien le robot, qui navigue jusqu'à la zone de la base. Le guidage terminal IR semble le seul maillon mort
3. `cleaningrecord.stc` : 5 nettoyages démarrés / 0 terminés depuis le dernier reset des stats, 1 kidnap avec échec de récupération
4. Historique ancien sain : 26 sessions terminées `(Docked)` — le mécanisme d'arrimage fonctionnait auparavant

Éléments secondaires : `LastMainboardError.txt` signale « Vision board was reset » mais daté du milieu de l'historique (pas la cause actuelle) ; 2 arrêts d'urgence récents `Wheeldrop Motion Fail` ; sessions 459 et 461 tronquées sans ligne de fin (crash ou coupure brutale). Firmware rev. 16552 (2015/11/12), bootloader 201, modèle n° 1762.

**Premier test caméra** (validé par contrôle : la caméra frontale voit bien l'IR d'une télécommande TV) : aucun point IR visible sur la fenêtre avant de la base → conclusion provisoire, base HS. Mais le robot **charge** quand on le pose manuellement dessus, donc l'alimentation de la base n'était pas en cause — seule son émission IR semblait morte.

### Panne n°2 — le robot tourne en rond : roue gauche ✅

Symptôme complémentaire : au lancement d'un nettoyage, le robot pivote sur place (~40°, avant/arrière, vers la gauche) et ne nettoie jamais.

**Session test 475** (nettoyage lancé ~4 min sans intervention) : log quasi vide — `Begin`, `VC_MAP_ROT_READY/ACK` (vision OK), puis rien pendant 3 min 40 (aucun `RobotPose`, aucun `Bumping`). Le robot n'entre jamais en phase de nettoyage ; le pare-chocs est électriquement muet (pas grippé).

**Test décisif — pilotage manuel à la télécommande** (commande moteur directe, sans navigation) :
- Tourner à gauche : OK (mouvement porté par la roue droite)
- Tourner à droite : ne répond pas (mouvement porté par la roue gauche)
- Tout droit : dérive à gauche

→ **Le module de roue gauche ne motrice plus.** Cohérent avec un `Left Wheel Stuck` dans l'historique ancien et les `Wheeldrop Motion Fail` récents.

### Cause unique ? — remise en question de la panne « base »

Deux pannes simultanées étant statistiquement suspectes, retour sur la chronologie de la blackbox :

```
451–456   arrimages automatiques réussis, y compris en batterie faible
457       nettoyage complet, fini sur la base
459       log TRONQUÉ en plein homing (crash ou coupure brutale)
460       DockNoSinal → « Not Docking »
461       log tronqué à nouveau
466, 469  urgences Wheeldrop / roue
→ plus aucun arrimage réussi ensuite
```

**Tout casse dans la même fenêtre de sessions** (457 → 460). Or le faisceau IR de la base est étroit et directionnel : l'arrimage final exige que le robot balaye et s'aligne — exactement ce qu'une roue gauche morte empêche. Un `DockNoSinal` peut donc signifier « la base n'émet pas » **ou** « je n'ai pas pu orienter mes récepteurs vers le faisceau ». Hypothèse retenue : cause unique = la roue, à confirmer après réparation.

### Réparation — roue gauche ✅ RÉSOLU

Robot ouvert (capot inférieur déposé) : blocs roue L/R accessibles, chacun avec moteur DC + disque d'encodeur + carte encodeur (réf. EBR743xx) + microswitch de roue pendante.

- **Cause trouvée à l'œil**, en réanalysant les photos de démontage, par mon papa : un fil du faisceau moteur/encodeur gauche était **sectionné** à l'endroit où il formait un coude à 180° juste au-dessus du ressort de suspension de la roue — le mouvement répété de haut en bas du ressort a fini par le cisailler à ce pli au fil des ~216h d'usage, plutôt qu'un défaut de fabrication
- Dénudage des deux brins, torsadage, **soudure**, gaine thermorétractable, fil reroutée pour éliminer le coude et l'écarter du débattement du ressort
- Test à la télécommande après réparation : tourner à droite et tout droit fonctionnent à nouveau normalement
- Test d'arrimage automatique (homing normal) : **le robot s'arrime à nouveau tout seul** ✅

**Conclusion finale** : fil sectionné par usure mécanique au niveau d'un coude à 180°, sous l'effet du débattement répété du ressort de suspension de la roue — réparé par soudure. Pas besoin de remplacer moteur, encodeur, carte mère ou base de charge. Le `DockNoSinal` était bien une conséquence de la roue morte, pas une base HS.

## ⚠️ Avertissement

Le script `update.sh` fourni est volontairement non destructif (lecture/copie uniquement), mais tout passage de script sur votre robot reste à vos risques. Ne modifiez rien sur le système de fichiers du robot sans savoir exactement ce que vous faites.
