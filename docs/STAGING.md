# Déploiement en staging

Cette procédure reste volontairement indépendante du fournisseur. Elle s'applique à toute plateforme capable d'exécuter l'image Docker et un processus de release.

## Topologie minimale

- Une base PostgreSQL persistante.
- Un processus `web` exposé en HTTPS.
- Un processus `worker` exécutant `bin/jobs`.
- Un processus ponctuel `release` exécutant `bin/rails db:prepare`.
- Un stockage S3 ou compatible pour les photos.
- Un service SMTP transactionnel.

Le `web` et le `worker` doivent utiliser la même version d'image, la même base, les mêmes secrets et le même stockage.

## Variables

Reporter les variables de `.env.example` dans le gestionnaire de secrets de la plateforme. Ne jamais importer le fichier `.env` local.

Variables indispensables :

- `APP_HOST`
- `SECRET_KEY_BASE`
- `DATABASE_URL`
- `ACTIVE_STORAGE_SERVICE`
- `MAILER_FROM`
- `SMTP_ADDRESS`

Pour `ACTIVE_STORAGE_SERVICE=amazon`, configurer également le bucket, la région et les identifiants adaptés au fournisseur. `OPENAI_API_KEY` est nécessaire pour le scan photo, mais les plans disposent d'un catalogue local de secours.

## Ordre de déploiement

1. Créer une sauvegarde PostgreSQL avant la première migration.
2. Construire une image à partir du commit fusionné.
3. Exécuter `bin/rails db:prepare` avec la future image.
4. Démarrer ou remplacer le processus `worker`.
5. Démarrer ou remplacer le processus `web`.
6. Attendre que `/health` renvoie `200`.
7. Lancer le smoke test depuis une machine extérieure à la plateforme.

```bash
STAGING_URL=https://staging.example.com bin/staging-smoke
```

Le script vérifie Rails, PostgreSQL, la page publique, les en-têtes de sécurité et les ressources PWA. Il retourne un code non nul dès qu'un contrôle échoue.

## Recette réelle

- Créer un compte et terminer l'onboarding.
- Générer un plan et vérifier son actualisation asynchrone.
- Remplacer un repas et verrouiller une recette.
- Générer la liste de courses, cocher un article et actualiser les prix.
- Envoyer une photo JPG, PNG ou WebP et confirmer les ingrédients détectés.
- Demander une réinitialisation de mot de passe et contrôler la réception de l'email.
- Installer la PWA sur un téléphone et vérifier l'écran hors ligne.

## Observabilité

Surveiller au minimum :

- Le taux de réponses `5xx` et la latence HTTP.
- Les jobs Solid Queue échoués ou bloqués.
- La disponibilité de PostgreSQL et l'espace disque.
- Les erreurs OpenAI, SMTP et stockage objet.
- Le taux de réussite des générations de plans et des scans.

## Rollback

Conserver l'image précédemment déployée. En cas d'incident :

1. Arrêter le déploiement progressif.
2. Revenir à l'image précédente pour `web` et `worker`.
3. Ne restaurer la base que si une migration est explicitement incompatible.
4. Relancer `bin/staging-smoke` après le rollback.
