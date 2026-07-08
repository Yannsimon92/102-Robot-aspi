# Diagnostic LG Hom-Bot Square VR6347LV

Extraction de logs par clé USB pour diagnostiquer un **LG Hom-Bot Square VR6347LV** qui tourne en rond et passe devant sa station de charge sans s'y arrimer.

Le robot tourne sous Linux embarqué et exécute un script `update.sh` placé à la racine d'une clé USB au démarrage (mécanisme de mise à jour firmware). Ce projet exploite ce mécanisme en **lecture seule** : aucun hack Wi-Fi, aucun SSH, aucune modification du robot — uniquement une copie des logs et de la configuration vers la clé.

## Contenu

| Fichier | Rôle |
|---|---|
| [update.sh](update.sh) | Script de diagnostic à copier à la racine d'une clé USB FAT32. Copie logs système, `dmesg`, points de montage, arborescence et config vers un dossier `diag/` sur la clé. Lecture/copie uniquement. |
| [DIAGNOSTIC.md](DIAGNOSTIC.md) | Notes complètes : symptôme, causes probables, procédure de test, points de vigilance. |

## Utilisation rapide

1. Formater une clé USB en **FAT32**, copier `update.sh` à sa racine (ne pas l'éditer sous Windows : les fins de ligne CRLF cassent le `#!/bin/sh`)
2. Robot éteint → insérer la clé (port USB sous le capot supérieur, derrière le cache caoutchouc) → allumer → START
3. Attendre l'annonce vocale de fin, éteindre, retirer la clé
4. Lire le dossier `diag/` généré sur la clé — commencer par `mounts.txt` et `dmesg.txt`

## ⚠️ Avertissement

Toute la documentation communautaire (repo `pocketbroadcast/hombot-tools`, roboter-forum.com) concerne la gamme **ronde classique** (VR64703 et similaires). **Rien n'est confirmé pour le châssis Square (VR6347LV).** Le script est volontairement non destructif, mais à utiliser à vos risques. Si le robot ne joue pas le son « here we go » à l'insertion de la clé, le firmware Square attend probablement autre chose — ne pas insister à l'aveugle.
