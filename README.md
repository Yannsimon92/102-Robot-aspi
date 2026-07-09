# Diagnostic LG Hom-Bot Square VR6347LV

Diagnostic et réparation, **réussie**, d'un **LG Hom-Bot Square VR6347LV** qui ne s'arrimait plus à sa base et tournait en rond au lieu de nettoyer. Le diagnostic a été mené **sans démontage et sans modification du robot** : uniquement par extraction de logs via clé USB, en exploitant le mécanisme `update.sh` du firmware — un vrai démontage n'a eu lieu qu'une fois la roue gauche formellement désignée comme coupable.

À notre connaissance, c'est la première documentation publique de ce mécanisme sur le châssis **Square** (la doc communautaire existante — `pocketbroadcast/hombot-tools`, roboter-forum — ne couvrait que la gamme ronde VR63xx/VR64xx). Verdict : le mécanisme est **identique**.

## Résultat du diagnostic — ✅ résolu

**Une seule panne réelle** : un fil du faisceau moteur/encodeur de la roue gauche, sectionné par frottement contre un arbre rotatif interne après ~216h d'usage. Repéré à l'œil (par le père de l'utilisateur, en réanalysant les photos de démontage) puis ressoudé. Le symptôme « base introuvable » (`DockNoSinal` dans la blackbox) n'était qu'une conséquence : le robot ne pouvait pas s'aligner sur le faisceau IR sans sa roue gauche — la base elle-même n'a jamais été en cause.

| Panne | Preuve | Résultat |
|---|---|---|
| Le **module de roue gauche ne motrice plus** (le robot pivote sur place au lieu de nettoyer) | Pilotage manuel à la télécommande : gauche OK, droite KO, dérive à gauche en marche avant ; log de session vide (jamais de phase de nettoyage, pare-chocs muet) | ✅ **Résolu** — fil sectionné, ressoudé, gaine thermorétractable, fil reroutée à l'écart de l'arbre |
| L'**arrimage à la base échouait** (`DockNoSinal` : aucun signal IR reçu à ~30 cm de la base) | Blackbox + chronologie montrant que tout cassait dans la même fenêtre de sessions (457→460) | ✅ **Résolu par la même réparation** — le robot s'arrime de nouveau tout seul |

Détail complet (méthode, journal des essais, analyse des logs, démontage, réparation) dans [DIAGNOSTIC.md](DIAGNOSTIC.md).

## Contenu du dépôt

| Fichier / dossier | Rôle |
|---|---|
| [update.sh](update.sh) | Script de dump à copier à la racine d'une clé USB FAT32. Lecture/copie uniquement. Copie blackbox, config et logs vers la clé. |
| [DIAGNOSTIC.md](DIAGNOSTIC.md) | Journal complet du diagnostic : procédure, essais, analyse, conclusions. |
| [diag/](diag/) | Dump n°1 : identité système, points de montage, `dmesg`, arborescence complète du robot. |
| [diag2/](diag2/) | Dump n°2 : `rc.local`, config applicative (`/usr/rcfg`), erreur carte mère, statistiques. Les données privées (cartes du logement, SLAM, trajectoires, n° de série) sont exclues du dépôt. |

## Ce qu'il faut savoir sur le mécanisme `update.sh` (châssis Square)

- Le script doit contenir la ligne-marqueur **`#IS_HIT_UPDATE_SCRIPT=1`**, sinon le firmware l'ignore silencieusement
- La clé (FAT32) est montée sur `/mnt/usb` ; le script est lancé en root par `/usr/etc/rc.local` au démarrage
- Fins de ligne **Unix (LF)** obligatoires — ne pas éditer le script sous Windows/Notepad
- Procédure : robot éteint → clé insérée (port USB sous le capot, derrière le cache caoutchouc) → allumer → START → attendre le son de fin
- Les journaux de session `cleanlog*.bbl` de la blackbox (`/usr/data/blackbox`) sont du **CSV texte lisible** : un événement horodaté par ligne
- Bonus trouvés dans `rc.local` : un dossier `blackbox/` sur la clé déclenche un export officiel de la boîte noire ; un dossier `debug/` active les core dumps ; un dongle Wi-Fi au boot lance `dropbear` (SSH) — le hack Wi-Fi de la gamme ronde s'applique donc au Square

## Système embarqué (pour référence)

SoC Nexell MOST2120 (ARMv6), Linux 2.6.33-rt PREEMPT_RT, rootfs squashfs lecture seule, données persistantes en UBIFS sur `/usr` et `/usr/data`, busybox. Firmware rev. 16552 (2015), caméra plafond OV7675 pour le VSLAM.

## ⚠️ Avertissement

Le script fourni est volontairement non destructif (lecture/copie uniquement), mais tout passage de script sur votre robot reste à vos risques. Ne modifiez rien sur le système de fichiers du robot sans savoir exactement ce que vous faites.
