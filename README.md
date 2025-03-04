# Planificateur de Recettes

## Description du Projet

Le Planificateur de Recettes est une application web qui permet aux utilisateurs de créer des plans de repas personnalisés en fonction de leurs préférences alimentaires, de leurs restrictions diététiques et des ingrédients de saison. L'application génère des recettes en utilisant l'API OpenAI, offrant ainsi une expérience culinaire unique et adaptée à chaque utilisateur.

### Fonctionnalités Principales

- **Création de Plans de Repas** : Les utilisateurs peuvent créer des plans de repas pour une période donnée, en spécifiant le nombre de portions, le temps de préparation maximum et les restrictions alimentaires.
- **Génération de Recettes** : L'application utilise l'API OpenAI pour générer des recettes basées sur les contraintes définies par l'utilisateur.
- **Gestion des Recettes** : Les utilisateurs peuvent consulter, créer, modifier et supprimer des recettes.
- **Affichage des Ingrédients de Saison** : Les recettes générées privilégient les ingrédients de saison pour une cuisine plus fraîche et durable.

## Prérequis

Avant de commencer, assurez-vous d'avoir installé les éléments suivants :

- Ruby (version 2.7 ou supérieure)
- Rails (version 6.0 ou supérieure)
- PostgreSQL (ou un autre système de gestion de base de données compatible)


## Installation

1. **Clonez le dépôt** :

   ```bash
   git clone https://github.com/Xav-uoafel/OnMangeQuoiCeSoir.git
   cd OnMangeQuoiCeSoir
   ```

2. **Installez les dépendances** :

   ```bash
   bundle install
   ```

3. **Configurez la base de données** :

   Créez un fichier `.env` à la racine du projet et ajoutez votre clé API OpenAI :

   ```bash
   OPENAI_API_KEY=your_openai_api_key
   ```

   Ensuite, exécutez les migrations de la base de données :

   ```bash
   rails db:create
   rails db:migrate
   rails db:seed # Afin de peupler la base de données avec des recettes de test
   ```

## Lancer l'Application

Pour démarrer le serveur local, exécutez :

```bash
bin/dev
ou 
rails server
```

Vous pouvez maintenant accéder à l'application à l'adresse suivante : [http://localhost:3000](http://localhost:3000).

## Tests

Pour exécuter les tests de l'application, utilisez la commande suivante :

```bash
rails test
```

## Contribuer

Les contributions sont les bienvenues ! Si vous souhaitez contribuer à ce projet, veuillez suivre ces étapes :

1. Forkez le projet.
2. Créez une nouvelle branche (`git checkout -b feature/YourFeature`).
3. Apportez vos modifications et validez-les (`git commit -m 'Add some feature'`).
4. Poussez votre branche (`git push origin feature/YourFeature`).
5. Ouvrez une Pull Request.
