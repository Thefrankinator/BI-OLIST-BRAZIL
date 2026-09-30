---
tags: [projet, bi, powerbi, pentaho, sqlserver, olist]
statut: à-faire
---

# Projet BI — Olist (E-commerce Brésil)

Pipeline complet : **CSV bruts → Pentaho (ETL) → SQL Server (entrepôt) → Power BI (reporting)**

Objectif final : un dashboard Power BI répondant à de vraies questions business (ventes, satisfaction client, délais de livraison, performance vendeurs) à partir de données réelles.

---

## Étape 0 — Préparer l'environnement

- [x] Installer **SQL Server** (édition Express ou Developer, gratuites) + **SQL Server Management Studio (SSMS)**
- [x] Installer **Pentaho Data Integration (PDI / Spoon)** — édition Community
	- [x] Installer le **pilote JDBC Microsoft pour SQL Server** dans Pentaho (`mssql-jdbc-x.x.x.jre.jar`, téléchargé chez Microsoft, à placer dans le dossier `lib` de PDI — sinon la connexion échouera)
- [x] Installer **Power BI Desktop**
- [x] Dans SSMS, créer une base vide, ex. `olist_dw` (dw = data warehouse)
- [x] Vérifier que **l'authentification SQL Server** (mode mixte) est activée si tu comptes te connecter avec un login/mot de passe depuis Pentaho, sinon utiliser l'authentification Windows partout

---

## Étape 1 — Récupérer et explorer les données

- [x] Télécharger le dataset **"Brazilian E-Commerce Public Dataset by Olist"** sur Kaggle
- [x] Dézipper et lister les fichiers CSV obtenus (normalement ~9 fichiers : commandes, clients, produits, vendeurs, paiements, avis, items de commande, géolocalisation, traduction des catégories)
- [x] Ouvrir chaque CSV et noter pour chacun :
  - le nombre de lignes / colonnes
  - le type de chaque colonne (texte, date, numérique, id)
  - la clé primaire probable
  - les colonnes qui font le lien avec les autres fichiers (clés étrangères)
- [x] Repérer les problèmes de qualité de données à corriger plus tard (valeurs manquantes, doublons, formats de date incohérents, encodage des caractères portugais)
- [x] Consulter le dictionnaire de données fourni par Olist sur Kaggle pour confirmer la signification de chaque table/colonne

---

## Étape 2 — Concevoir le modèle cible (schéma en étoile)

Avant de toucher à Pentaho, définir sur papier (ou dans un outil de modélisation) la structure cible dans MySQL.

- [x] Identifier la **table de faits** centrale : les lignes de commande (`order_items`), avec les mesures numériques (prix, frais de port, quantité)
- [x] Identifier les **tables de dimensions** autour :
  - dimension client (localisation, id client)
  - dimension produit (catégorie, poids, dimensions)
  - dimension vendeur (localisation, id vendeur)
  - dimension date/temps (à générer, pas fournie telle quelle — année, mois, jour, trimestre)
  - dimension avis/satisfaction (note, commentaire, délai de réponse)
  - dimension paiement (type, nombre de mensualités)
- [x] Dessiner le schéma en étoile (table de faits au centre, dimensions autour, clés étrangères)
- [x] Écrire le script T-SQL de création des tables cibles (`CREATE TABLE`, clés primaires, clés étrangères, types de colonnes — attention aux types spécifiques SQL Server : `NVARCHAR` pour le texte avec accents/portugais, `DATETIME2` pour les dates, `IDENTITY(1,1)` pour les auto-incréments)
- [x] Exécuter ce script dans SSMS pour créer la structure vide dans `olist_dw`

---

## Étape 3 — Construire l'ETL dans Pentaho

Pour **chaque fichier CSV source**, créer une *transformation* Pentaho dédiée :

- [x] **Extraction** : étape "CSV file input" pointant vers le fichier source
- [x] **Nettoyage** : suppression des doublons, gestion des valeurs nulles, conversion des types (dates, nombres), correction d'encodage si besoin
- [x] **Transformation** : renommage des colonnes selon le modèle cible, calculs dérivés si nécessaire (ex. extraire année/mois d'une date pour la dimension temps)
- [x] **Chargement** : étape "Table output" vers la table SQL Server correspondante dans `olist_dw` (créer la connexion Pentaho de type "MS SQL Server (native)" ou via JDBC)

Ensuite :

- [x] Créer un **job Pentaho** qui enchaîne toutes les transformations dans le bon ordre (dimensions d'abord, table de faits en dernier, pour respecter les clés étrangères)
- [x] Ajouter une gestion d'erreur basique dans le job (arrêt ou log si une transformation échoue)
- [x] Exécuter le job complet et vérifier dans les logs Pentaho qu'aucune ligne n'est rejetée sans raison

---

## Étape 4 — Contrôler la qualité des données chargées

- [x] Dans SSMS, vérifier le nombre de lignes chargées par table (comparer au nombre de lignes des CSV source)
- [x] Vérifier qu'il n'y a pas de clés étrangères orphelines (ex. une commande référençant un client inexistant)
- [x] Tester quelques requêtes SQL de contrôle (jointures entre table de faits et dimensions, agrégats simples : total des ventes, nombre de commandes par mois)
- [x] Corriger et relancer l'ETL Pentaho si des anomalies sont trouvées

---

## Étape 5 — Connecter Power BI à SQL Server

- [x] Aucun pilote supplémentaire n'est normalement nécessaire : Power BI Desktop a un connecteur natif SQL Server
- [x] Dans Power BI Desktop : Obtenir des données → Base de données SQL Server → renseigner le nom du serveur (ex. `localhost` ou `NOMPC\SQLEXPRESS`) et la base `olist_dw`
- [x] Choisir le mode d'authentification (Windows ou SQL Server selon ce qui a été configuré à l'étape 0)
- [x] Choisir **Import** (plutôt que DirectQuery) pour ce projet d'entraînement, plus simple et plus rapide pour manipuler les mesures DAX
- [x] Importer les tables de faits et de dimensions créées à l'étape 2
- [x] Vérifier/recréer les relations entre tables dans la vue "Modèle" de Power BI (elles ne sont pas toujours détectées automatiquement)

---

## Étape 6 — Définir les questions business et les mesures DAX

- [x] Lister 4 à 6 questions métier précises, par exemple :
  - Quel est le chiffre d'affaires total et son évolution mensuelle ?
  - Quelles sont les catégories de produits les plus vendues ?
  - Quel est le délai de livraison moyen, et varie-t-il selon la région ?
  - Quelle est la note moyenne de satisfaction client, et est-elle liée au délai de livraison ?
  - Quels sont les vendeurs les plus performants ?
- [x] Écrire les mesures DAX correspondantes (CA total, nombre de commandes, panier moyen, délai moyen de livraison, note moyenne, etc.)
- [x] Créer les colonnes calculées nécessaires si une mesure ne suffit pas (ex. catégorie de délai : rapide/normal/lent)

---

## Étape 7 — Construire le rapport Power BI

- [ ] Définir un plan de mise en page (1 page vue d'ensemble, 1 page produits, 1 page logistique/satisfaction, 1 page vendeurs par exemple)
- [ ] Choisir les visuels adaptés à chaque question (carte pour la géographie, courbe pour l'évolution temporelle, barres pour les comparaisons de catégories)
- [ ] Ajouter des filtres/segments (slicers) : période, région, catégorie de produit
- [ ] Soigner la mise en forme (titres clairs, couleurs cohérentes, alignement)

---

## Étape 8 — Finaliser et documenter

- [ ] Relire le dashboard du point de vue d'un utilisateur qui découvre les données pour la première fois
- [ ] Exporter/publier le rapport (PDF, Power BI Service, ou partage du .pbix)
- [ ] Rédiger une courte documentation du projet : schéma en étoile final, choix faits pendant l'ETL, difficultés rencontrées
- [ ] (Optionnel) Planifier le job Pentaho (via Carte ou un scheduler) pour simuler un rafraîchissement automatique des données

---

## Notes

- Le dataset Olist est en portugais brésilien pour certaines valeurs (catégories de produits notamment) — un fichier de traduction est fourni dans le dataset, à utiliser lors de l'ETL.
- Respecter l'ordre de chargement dans SQL Server (dimensions avant faits) pour éviter les erreurs de clé étrangère, ou désactiver temporairement les contraintes (`ALTER TABLE ... NOCHECK CONSTRAINT ALL`) si le job Pentaho ne permet pas de garantir l'ordre.
- Garder une copie des CSV bruts non modifiés à part, pour pouvoir relancer l'ETL depuis zéro si besoin.
- Si SQL Server tourne sur la même machine, vérifier que le **service SQL Server Browser** est actif et que le port TCP (1433 par défaut) est ouvert, sinon Pentaho et Power BI ne pourront pas s'y connecter.
