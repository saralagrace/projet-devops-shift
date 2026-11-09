# SHIFT — Laboratoire DevOps & automatisation d'infrastructure

![Statut](https://img.shields.io/badge/statut-laboratoire%20fonctionnel-2ea44f)
![Infrastructure](https://img.shields.io/badge/Infrastructure-Proxmox%20%7C%20Terraform-blue)
![Déploiement](https://img.shields.io/badge/D%C3%A9ploiement-Ansible%20%7C%20Docker-orange)
![OS](https://img.shields.io/badge/OS-Ubuntu%20Server-E95420)

> **Du provisionnement d'une machine virtuelle à la publication d'une application web : un laboratoire pratique pour comprendre et automatiser chaque étape d'un déploiement.**

## Sommaire

- [Présentation](#présentation)
- [Objectifs pédagogiques](#objectifs-pédagogiques)
- [Architecture du laboratoire](#architecture-du-laboratoire)
- [Technologies utilisées](#technologies-utilisées)
- [Structure du dépôt](#structure-du-dépôt)
- [Fonctionnement du déploiement](#fonctionnement-du-déploiement)
- [Prérequis](#prérequis)
- [Démarrage et vérification](#démarrage-et-vérification)
- [Automatisation Ansible et idempotence](#automatisation-ansible-et-idempotence)
- [Infrastructure as Code avec Terraform](#infrastructure-as-code-avec-terraform)
- [Versionnement et collaboration](#versionnement-et-collaboration)
- [Sécurité et bonnes pratiques](#sécurité-et-bonnes-pratiques)
- [Dépannage](#dépannage)
- [État d'avancement et perspectives](#état-davancement-et-perspectives)
- [Autrice](#autrice)

## Présentation

**SHIFT** est un projet de formation et d'expérimentation autour des pratiques **DevOps**, de la **virtualisation**, de l'**Infrastructure as Code (IaC)** et de l'**automatisation des déploiements**.

Le laboratoire s'appuie sur un serveur **Proxmox VE** et une machine virtuelle **Ubuntu Server** sur laquelle une application web statique est exécutée par **Nginx** dans un conteneur **Docker**. **Docker Compose** décrit le service, tandis qu'**Ansible** prépare et déploie l'application. **Terraform** est utilisé séparément pour expérimenter la création de machines virtuelles sur Proxmox.

Ce dépôt documente **le laboratoire réalisé à ce jour**. Il constitue un socle technique pour les fonctionnalités plus larges envisagées dans SHIFT ; ce n'est pas encore une plateforme web d'orchestration complète.

## Objectifs pédagogiques

- Comprendre le rôle d'un hyperviseur et d'une machine virtuelle.
- Déclarer une infrastructure avec Terraform et comprendre `init`, `plan` et `apply`.
- Installer et administrer les outils nécessaires sur Ubuntu.
- Construire une image Docker à partir d'un `Dockerfile`.
- Décrire et exploiter une application avec Docker Compose.
- Automatiser la configuration et le déploiement avec Ansible.
- Utiliser les **handlers** pour déclencher des actions uniquement lorsqu'un changement le nécessite.
- Vérifier l'**idempotence** des playbooks Ansible.
- Versionner les configurations et le code avec Git et GitHub.
- Préparer l'intégration continue, les contrôles de sécurité et la supervision.

## Architecture du laboratoire

```text
                      ┌───────────────────────────┐
                      │      Proxmox VE           │
                      │   Hôte de virtualisation  │
                      └─────────────┬─────────────┘
                                    │
               ┌────────────────────┴────────────────────┐
               │                                         │
    ┌──────────▼──────────────┐                ┌─────────▼──────────────┐
    │ VM 100 — Ubuntu Server  │                │ VM 103 — créée avec   │
    │ Laboratoire applicatif  │                │ Terraform             │
    │                         │                │ Expérimentation IaC   │
    │  Ansible                │                │ (OS non configuré)    │
    │     │                   │                └────────────────────────┘
    │     ▼                   │
    │  Docker Compose         │
    │     │                   │
    │     ▼                   │
    │  Conteneur Nginx        │
    │     │                   │
    │     ▼                   │
    │  Site web statique      │
    │  http://localhost:8081  │
    └─────────────────────────┘
```

**Distinction importante :** la VM **100** héberge actuellement le site et les outils de déploiement. La VM **103** a été créée à titre d'exercice avec Terraform ; ce n'est pas le serveur qui publie le site. L'adresse `localhost:8081` est à utiliser **depuis la VM Ubuntu** ; depuis un autre poste, l'accès dépend de la connectivité réseau et du pare-feu.

### Parcours d'une modification

```text
Modification du contenu HTML dans le playbook
                    │
                    ▼
         Exécution d'Ansible
                    │
                    ▼
      Mise à jour de site/index.html
                    │
       (si le fichier a changé)
                    ▼
           Handler Ansible
                    │
                    ▼
        Reconstruction de l'image
                    │
                    ▼
      Actualisation du service Compose
                    │
                    ▼
          Site servi par Nginx
```

## Technologies utilisées

| Technologie | Rôle dans le laboratoire |
| --- | --- |
| **Proxmox VE** | Hébergement et gestion des machines virtuelles |
| **Ubuntu Server 24.04 LTS** | Système d'exploitation de la VM de travail |
| **Terraform** | Provisionnement d'une VM Proxmox via son API |
| **Ansible** | Configuration du serveur et déploiement automatisé |
| **Docker** | Construction de l'image et exécution du conteneur |
| **Docker Compose** | Définition et cycle de vie du service web |
| **Nginx** | Serveur HTTP dans le conteneur |
| **Git / GitHub** | Historique des modifications et hébergement du code |

## Structure du dépôt

```text
projet-devops/
├── .gitignore                  # Exclusions Git, notamment des états Terraform
├── Dockerfile                  # Image Nginx contenant le site
├── compose.yaml                # Définition du service web et du port 8081
├── preparation.yaml            # Préparation de l'environnement Ubuntu
├── deploiement.yaml            # Déploiement Ansible et handler Docker Compose
├── site/
│   ├── index.html              # Page web statique
│   └── suivi.txt               # Notes de suivi du laboratoire
├── terraform/
│   ├── main.tf                 # Configuration du fournisseur Proxmox
│   ├── vm.tf                   # Définition d'une VM pour l'exercice IaC
│   └── .terraform.lock.hcl     # Verrouillage des dépendances du provider
└── README.md                   # Documentation du projet
```

Les répertoires `.terraform/`, les fichiers `*.tfstate*` et les fichiers contenant des secrets ne doivent pas être publiés. Ils sont exclus via `.gitignore` ; une vérification manuelle reste indispensable avant chaque publication.

## Fonctionnement du déploiement

### 1. Construction de l'image Docker

Le `Dockerfile` s'appuie sur Nginx et copie le site dans le répertoire publié par le serveur :

```dockerfile
FROM nginx:stable
COPY site/ /usr/share/nginx/html/
```

**Conséquence :** modifier `site/index.html` sur Ubuntu ne modifie pas une image Docker déjà construite. Il faut reconstruire l'image puis mettre à jour le conteneur pour servir la nouvelle version.

### 2. Exécution du service avec Docker Compose

Le fichier `compose.yaml` décrit le service web et publie le port **8081 de la VM** vers le port **80 du conteneur Nginx**.

```text
VM Ubuntu : 8081  ─────────►  Conteneur Nginx : 80
```

Pour afficher la configuration exacte :

```bash
sudo docker compose config
```

### 3. Orchestration locale avec Ansible

Le playbook `deploiement.yaml` :

1. Vérifie et met à jour `site/index.html` grâce au module `ansible.builtin.copy`.
2. S'assure que le service web est présent avec `community.docker.docker_compose_v2`.
3. Déclenche un **handler** lorsqu'une modification du fichier a été détectée.
4. Reconstruit alors l'image et actualise le service avec Docker Compose.

Le handler évite de reconstruire systématiquement l'image lors d'une exécution sans changement du fichier HTML. Il s'agit du fonctionnement actuel du laboratoire, et non d'un mécanisme de détection automatique de toute modification du projet.

## Prérequis

Ce dépôt n'est pas un installateur universel : les commandes ci-dessous correspondent à un **laboratoire Ubuntu déjà préparé**.

Pour reproduire l'environnement, prévoir :

- Un hôte de virtualisation Proxmox VE pour les expériences de VM (facultatif pour exécuter simplement le site Docker).
- Une VM ou une machine Linux disposant d'un accès réseau et des ressources nécessaires.
- Docker Engine et Docker Compose v2.
- Ansible et la collection `community.docker`.
- Git pour récupérer et versionner les fichiers.
- Les droits nécessaires pour administrer Docker (`sudo` dans ce laboratoire).

Vérifier les outils installés :

```bash
docker --version
docker compose version
ansible --version
ansible-galaxy collection list community.docker
git --version
```

> Pour le déploiement Ansible, `deploiement.yaml` référence actuellement le chemin `/home/sara/projet-devops` et l'utilisateur `sara`. Ces valeurs doivent être adaptées si le projet est cloné dans un autre répertoire ou utilisé par une autre personne.

## Démarrage et vérification

### Vérifier la syntaxe du playbook

Depuis la racine du projet :

```bash
sudo ansible-playbook deploiement.yaml --syntax-check
```

### Déployer le site

```bash
sudo ansible-playbook deploiement.yaml
```

### Contrôler le conteneur

```bash
sudo docker compose ps
```

### Tester la réponse HTTP

```bash
curl -I http://localhost:8081
curl -s http://localhost:8081
```

Un fonctionnement correct doit notamment permettre d'obtenir une réponse **HTTP 200** et de voir dans le HTML :

```html
<h1>Bienvenue dans mon laboratoire DevOps SHIFT !</h1>
```

### Consulter les journaux du service

```bash
sudo docker compose logs --tail=50 web
```

## Automatisation Ansible et idempotence

L'**idempotence** est une propriété essentielle des automatisations d'infrastructure : relancer la même opération lorsque l'état souhaité est déjà atteint ne doit pas provoquer de modification inutile.

Dans le laboratoire, deux comportements ont été observés :

| Situation | Résultat observé | Interprétation |
| --- | --- | --- |
| Première exécution après modification du contenu HTML | `changed=2`, `failed=0` | Ansible modifie la page et déclenche le handler Docker |
| Nouvelle exécution sans modification | `changed=0`, `failed=0` | L'état demandé est déjà atteint ; le handler n'est pas relancé |

Le handler utilise le module `community.docker.docker_compose_v2` avec une politique de reconstruction de l'image lorsqu'il est notifié.

**Limite actuelle :** le handler est notifié par la tâche de création du fichier HTML. Une modification directe du `Dockerfile`, du `compose.yaml` ou d'autres fichiers du contexte de construction ne déclenche pas automatiquement ce handler. Un futur travail consistera à suivre ces modifications et à définir une stratégie de déploiement adaptée.

## Infrastructure as Code avec Terraform

Terraform permet de décrire une machine virtuelle sous forme de code puis de demander sa création à l'API Proxmox.

Dans le laboratoire, une **VM 103** a été provisionnée et démarrée par Terraform. L'installation et la configuration complète de son système d'exploitation ne font pas partie du déploiement de l'application hébergée sur la VM 100.

Commandes habituelles depuis le dossier Terraform :

```bash
cd terraform
terraform init
terraform fmt -check
terraform validate
terraform plan
```

`terraform apply` applique les changements proposés **uniquement après vérification du plan**, avec les identifiants Proxmox et les autorisations nécessaires configurés localement.

**Ne jamais saisir ni enregistrer un secret Proxmox en clair dans un fichier suivi par Git.** Les fichiers d'état Terraform peuvent aussi contenir des données sensibles : ils restent locaux dans ce laboratoire et ne sont pas versionnés.

## Versionnement et collaboration

Le dépôt GitHub centralise les fichiers de configuration et leur historique.

Commandes de base pour enregistrer une modification :

```bash
git status
git add README.md
git commit -m "Documentation du laboratoire DevOps SHIFT"
git push origin main
```

Pour travailler sur d'autres fichiers, sélectionner explicitement ceux à ajouter au commit, après vérification de leur contenu.

Dépôt : **[saralagrace/projet-devops-shift](https://github.com/saralagrace/projet-devops-shift)**.

## Sécurité et bonnes pratiques

- Ne jamais publier de **Personal Access Token GitHub**, de secret d'API Proxmox, de mot de passe ni de clé privée.
- Conserver les secrets hors des fichiers versionnés et limiter les droits accordés aux tokens.
- Vérifier les fichiers avec `git status`, `git diff --cached` et `git ls-files` avant un `git push`.
- Ne pas publier les fichiers `terraform.tfstate` et leurs sauvegardes.
- Régénérer tout identifiant exposé et vérifier qu'il n'est pas présent dans l'historique Git.
- Limiter les accès réseau et les permissions administrateur aux besoins du laboratoire.
- Éviter les images Docker non maîtrisées ; à terme, figer les versions et ajouter des analyses de sécurité.

> **Note :** `.gitignore` empêche l'ajout des fichiers correspondant aux motifs configurés, mais ne supprime pas les secrets déjà enregistrés dans un commit et ne remplace pas une revue de sécurité.

## Dépannage

| Problème | Vérification ou action |
| --- | --- |
| Ansible affiche `No inventory was parsed` | Ce laboratoire utilise `hosts: localhost` et `connection: local` ; l'avertissement n'empêche pas le playbook de s'exécuter. |
| Ansible modifie le HTML mais l'ancienne page reste visible | Vérifier que l'image a été reconstruite et que le conteneur utilise la nouvelle image. |
| `permission denied` sur `/var/run/docker.sock` | Dans ce laboratoire, utiliser les commandes Docker avec `sudo` et vérifier les droits. |
| Le port 8081 ne répond pas | Vérifier `sudo docker compose ps`, puis `sudo docker compose logs --tail=50 web`. |
| Avertissement Docker Compose sur Bake / Buildx | La reconstruction a pu fonctionner malgré cet avertissement ; vérifier le statut final et envisager l'installation/configuration de Buildx. |
| `git push` retourne une erreur 403 | Vérifier l'accès au dépôt et la permission **Contents: Read and write** du token GitHub. |

## État d'avancement et perspectives

### Réalisé

- [x] Mise en place du laboratoire Ubuntu sur Proxmox.
- [x] Installation et utilisation de Docker et Docker Compose.
- [x] Déploiement d'un site statique Nginx accessible sur le port 8081.
- [x] Automatisation du déploiement par Ansible.
- [x] Mise en place d'un handler pour reconstruire l'image après modification du HTML.
- [x] Validation pratique de l'idempotence Ansible.
- [x] Provisionnement expérimental d'une VM Proxmox avec Terraform.
- [x] Initialisation de Git et publication du dépôt sur GitHub.

### À développer

- [ ] Ajouter un pipeline **GitHub Actions** pour les vérifications automatiques.
- [ ] Tester automatiquement la syntaxe Ansible et les configurations du projet.
- [ ] Améliorer la gestion des modifications du Dockerfile et du contexte de construction.
- [ ] Mettre en place des contrôles de sécurité des images et des configurations.
- [ ] Ajouter la supervision et la collecte de journaux.
- [ ] Documenter une procédure de restauration et de retour arrière.
- [ ] Étudier l'extension du projet vers des environnements d'orchestration plus avancés.

## Autrice

**Sara Yatchou**  
Projet de formation pratique en infrastructure, systèmes, cloud et DevOps.

GitHub : [@saralagrace](https://github.com/saralagrace)

---

*Ce dépôt retrace un apprentissage progressif : chaque outil est utilisé dans un cas concret, puis ses interactions avec les autres composants sont expliquées et vérifiées.*
