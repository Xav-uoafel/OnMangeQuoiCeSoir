# OnMangeQuoiCeSoir

## Description du Projet

OnMangeQUoiCeSoir est une application web qui permet aux utilisateurs de créer des plans de repas personnalisés en fonction de leurs préférences alimentaires, de leurs restrictions diététiques et des ingrédients de saison. L'application génère des recettes en utilisant l'API OpenAI, offrant ainsi une expérience culinaire unique et adaptée à chaque utilisateur.

### Fonctionnalités Principales

- **Création de Plans de Repas** : Les utilisateurs peuvent créer des plans de repas pour une période donnée, en spécifiant le nombre de portions, le temps de préparation maximum et les restrictions alimentaires.
- **Génération de Recettes** : L'application utilise l'API OpenAI et bascule sur un catalogue local si le service est indisponible.
- **Génération Résiliente** : Chaque tentative est suivie, les anciens jobs sont neutralisés et une génération bloquée peut être relancée sans perdre les préférences.
- **Gestion des Recettes** : Les utilisateurs peuvent consulter, créer, modifier et supprimer des recettes.
- **Affichage des Ingrédients de Saison** : Les recettes générées privilégient les ingrédients de saison pour une cuisine plus fraîche et durable.
- **Stock et Scan** : Le stock peut être saisi manuellement ou préparé à partir de photos avant confirmation. Les analyses sont idempotentes, relançables avec les photos existantes et protégées contre les fichiers trop lourds.
- **Liste de Courses** : Les ingrédients manquants sont regroupés et accompagnés d'une estimation indicative du panier.
- **Application Mobile Installable** : Le manifeste PWA, les raccourcis et l'écran hors ligne permettent d'installer OnMangeQuoi sur l'écran d'accueil.

## Prérequis

Avant de commencer, assurez-vous d'avoir installé les éléments suivants :

- Ruby `3.4.2`
- Bundler `2.5.x` ou supérieure compatible
- Rails `8.0`
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
   OPENAI_MODEL=gpt-4.1-mini
   OPENAI_VISION_MODEL=gpt-4.1-mini
   OPENAI_VISION_DETAIL=high
   ```

   `OPENAI_API_KEY` est facultative pour les plans, qui disposent d'un catalogue local de secours, mais elle est nécessaire pour analyser les photos du stock.

   Ensuite, exécutez les migrations de la base de données :

   ```bash
   bin/rails db:prepare
   bin/rails db:seed # Données de démonstration idempotentes en développement
   ```

## Lancer l'Application

Pour démarrer le serveur local, exécutez :

```bash
bin/dev
# ou, sans le processus de compilation CSS
bin/rails server -p 3010
```

Vous pouvez maintenant accéder à l'application à l'adresse suivante : [http://localhost:3010](http://localhost:3010).

## Tests

Pour exécuter les tests de l'application, utilisez la commande suivante :

```bash
bundle exec rails test
bundle exec rails test:system
```

En dehors de l'environnement de développement, les données de démonstration ne sont créées que sur demande explicite avec `SEED_DEMO_DATA=1 bin/rails db:seed`.

## Déploiement en production

Copiez `.env.example` dans le gestionnaire de secrets de la plateforme et renseignez au minimum l'hôte public, PostgreSQL, l'email transactionnel et le stockage. Le démarrage refuse une configuration incomplète afin d'éviter une production partiellement fonctionnelle.

Générez `SECRET_KEY_BASE` avec `bin/rails secret` et conservez sa valeur uniquement dans le gestionnaire de secrets de la plateforme.

L'image Docker expose trois processus dans le `Procfile` :

- `release` exécute `bin/rails db:prepare` une seule fois avant la mise en ligne.
- `web` sert les requêtes HTTP.
- `worker` exécute Solid Queue avec `bin/jobs`; il doit rester actif pour la génération des plans, les scans et les estimations de prix.

Deux sondes sont disponibles : `/up` vérifie que Rails répond, tandis que `/health` vérifie aussi la connexion PostgreSQL et renvoie `503` si la base est indisponible. Le healthcheck Docker utilise `/health`.

Pour les photos, `ACTIVE_STORAGE_SERVICE=amazon` est recommandé avec un bucket S3 ou compatible. Le mode `local` n'est sûr que si le répertoire `/rails/storage` est monté sur un volume persistant partagé avec tous les processus web et worker.

Le scan accepte de 1 à 5 fichiers JPG, PNG ou WebP, avec une limite de 8 Mo par photo et de 20 Mo par envoi. Les images sont transmises au modèle Vision sous forme de données encodées : aucun blob Active Storage n'a besoin d'être exposé publiquement.

Les opérations coûteuses sont limitées par utilisateur et par fenêtre horaire. Les compteurs sont stockés dans PostgreSQL pour rester cohérents entre plusieurs processus, sans conserver d'email ni d'adresse IP, puis supprimés quotidiennement par Solid Queue.

Les contrôles CI couvrent les tests Rails et navigateur, RuboCop, Brakeman, Bundler Audit et la construction complète de l'image Docker.

La procédure complète de staging est documentée dans [`docs/STAGING.md`](docs/STAGING.md). Après chaque déploiement, exécutez le contrôle extérieur :

```bash
STAGING_URL=https://staging.example.com bin/staging-smoke
```

## Contribuer

Les contributions sont les bienvenues ! Si vous souhaitez contribuer à ce projet, veuillez suivre ces étapes :

1. Forkez le projet.
2. Créez une nouvelle branche (`git checkout -b feature/YourFeature`).
3. Apportez vos modifications et validez-les (`git commit -m 'Add some feature'`).
4. Poussez votre branche (`git push origin feature/YourFeature`).
5. Ouvrez une Pull Request.
