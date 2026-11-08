# Dépôt de l'équipe : TAMBOai Foundation

Ce dépôt est le **vôtre et celui de votre équipe** pour toute la formation. Tout le travail s'y trouve.

## Organisation
- Un **dossier par objectif** : `objectif-1-messagerie/`, puis `objectif-2-.../`, etc.
- Dans chaque objectif, un **sous-dossier par plateforme** choisie par l'équipe (ex. `android/`, `web/`, `windows/`).
- Les consignes de chaque objectif sont dans le `README.md` de son dossier.

## Règles de travail
1. **Ne poussez jamais directement sur `main` ni sur `develop`.** Créez votre branche **à partir de `develop`** : `objectif-1/<prénom>-<tâche>` (ex. `objectif-1/awa-environnement`).
2. Faites de petits commits clairs, en français ou en anglais.
3. Ouvrez une **Pull Request** vers `develop` en remplissant le modèle. Le **Team Lead** relit, approuve et fusionne. La formation fusionne ensuite `develop` vers `main` après validation.
4. **Aucun secret** dans le dépôt (mots de passe, clés, jetons). Si c'est arrivé : prévenez la formation tout de suite.
5. Respect : relisez avec bienveillance, expliquez vos remarques.

## Premiers pas
```
git clone <adresse du dépôt de votre équipe>
cd <dossier>
git checkout develop
git pull
git checkout -b objectif-1/<prénom>-<tâche>
```

## Aide
Posez vos questions à votre Team Lead, puis à la formation (contact@tamboai.co).
