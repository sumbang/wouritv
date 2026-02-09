# Guide de Déploiement CloudFront pour Vidéos Premium

## 1. Déployer la Supabase Edge Function

### Prérequis
- Installer Supabase CLI : `npm install -g supabase`
- Se connecter : `supabase login`

### Déploiement
```bash
# Depuis la racine du projet
cd /Users/sumbang/dev/mobile/wouritv

# Déployer la fonction
supabase functions deploy generate-signed-url --project-ref efpkxqfqlhzfvwpmejfp

# Configurer les secrets (variables d'environnement)
supabase secrets set CLOUDFRONT_KEY_PAIR_ID=VOTRE_KEY_PAIR_ID --project-ref efpkxqfqlhzfvwpmejfp
supabase secrets set CLOUDFRONT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
VOTRE_CLE_PRIVEE_ICI
-----END PRIVATE KEY-----" --project-ref efpkxqfqlhzfvwpmejfp
```

### Vérifier le déploiement
```bash
# Lister les fonctions déployées
supabase functions list --project-ref efpkxqfqlhzfvwpmejfp

# Voir les logs en temps réel
supabase functions logs generate-signed-url --project-ref efpkxqfqlhzfvwpmejfp
```

## 2. Configurer AWS CloudFront

### Étape 1 : Créer une distribution CloudFront

1. **Créer le bucket S3 pour les vidéos premium**
   ```bash
   # Dans AWS Console → S3 → Create Bucket
   # Nom: wouritv-premium-videos
   # Region: eu-west-1 (ou votre région préférée)
   # Bloquer tous les accès publics: OUI (CloudFront accèdera via OAI)
   ```

2. **Créer la distribution CloudFront**
   - Allez dans CloudFront → Create Distribution
   
   **Origin Settings:**
   - **Origin Domain** : `wouritv-premium-videos.s3.eu-west-1.amazonaws.com`
   - **Origin Path** : (laisser vide, on utilisera des chemins complets comme `premium/film-1.mp4`)
   - **S3 Bucket Access** : Yes, use OAI (Origin Access Identity)
   - **Origin Access Identity** : Create New Identity
   - **Bucket Policy** : Yes, update the bucket policy (AWS le fera automatiquement)
   
   **Default Cache Behavior:**
   - **Viewer Protocol Policy** : Redirect HTTP to HTTPS
   - **Allowed HTTP Methods** : GET, HEAD, OPTIONS
   - **Cache Policy** : CachingOptimized (ou créer une custom policy)
   - **Compress Objects Automatically** : Yes

   **Distribution Settings:**
   - **Price Class** : Use Only North America and Europe (ou selon vos besoins)
   - **AWS WAF Web ACL** : None
   - **Alternate Domain Names (CNAMEs)** : videos.wouritv.com (optionnel, si vous avez un domaine)
   - **SSL Certificate** : Default CloudFront Certificate (ou votre certificat ACM)

3. **Récupérer le domaine CloudFront**
   - Après création, notez le **Domain Name** : `d1234567890abc.cloudfront.net`
   - C'est ce domaine que vous utiliserez dans `CLOUDFRONT_DOMAIN`

### Étape 2 : Activer les URL signées

1. Dans votre distribution, allez dans **Behaviors** → Edit
2. **Restrict Viewer Access** : Yes
3. **Trusted Signers** → **Trusted Key Groups** : Create New Key Group

### Étape 3 : Créer une paire de clés CloudFront

```bash
# Générer une paire de clés RSA (2048 bits minimum)
openssl genrsa -out cloudfront-private-key.pem 2048

# Extraire la clé publique
openssl rsa -pubout -in cloudfront-private-key.pem -out cloudfront-public-key.pem
```

### Étape 4 : Ajouter la clé publique à CloudFront

1. Allez dans **CloudFront** → **Key Management** → **Public Keys**
2. Cliquez sur **Create Public Key**
3. Collez le contenu de `cloudfront-public-key.pem`
4. Nommez-la `wouritv-premium-key`
5. Créez un **Key Group** et ajoutez cette clé

### Étape 5 : Récupérer les informations nécessaires

```bash
# Key Pair ID (visible dans la console CloudFront)
# Format : K2JCJMDEHXQW5F

# Clé privée (contenu de cloudfront-private-key.pem)
cat cloudfront-private-key.pem
# Copiez TOUT le contenu incluant -----BEGIN PRIVATE KEY----- et -----END PRIVATE KEY-----
```

### Étape 6 : Configurer les secrets Supabase

**IMPORTANT** : Vous n'avez PAS besoin des credentials S3 (access key, secret, bucket name, region) dans le code ou la Edge Function. CloudFront accède directement à S3 via une Origin Access Identity configurée dans AWS.

Les seuls secrets nécessaires sont :

```bash
# 1. Domaine CloudFront (trouvé dans AWS Console → CloudFront → Your Distribution → Domain Name)
# Exemple: d1234567890abc.cloudfront.net
supaConfiguration AWS CLI (une seule fois)

```bash
# Installer AWS CLI
brew install awscli  # sur macOS
# ou: pip install awscli

# Configurer avec vos credentials AWS (IAM User avec accès S3)
aws configure
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region name: eu-west-1
# Default output format: json
```

**Note**: Ces credentials AWS sont utilisés UNIQUEMENT pour uploader les vidéos sur S3 depuis votre ordinateur. Ils ne sont PAS nécessaires dans le code Flutter ou la Edge Function.

### Structure recommandée dans S3
```
s3://wouritv-premium-videos/
  ├── premium/
  │   ├── film-1.mp4
  │   ├── film-2.mp4
  │   ├── film-3.m3u8  (HLS streaming)
  │   └── serie-1/
  │       ├── episode-1.mp4
  │       └── episode-2.mp4
  ├── documentaires/
  │   └── nature.mp4
```

### Upload des vidéos
```bash
# Uploader un fichier
aws s3 cp film-1.mp4 s3://wouritv-premium-videos/premium/film-1.mp4

# Uploader un dossier complet
aws s3 cp ./mes-videos/ s3://wouritv-premium-videos/premium/ --recursive

# Vérifier les fichiers uploadés
aws s3 ls s3://wouritv-premium-videos/premium/
```

### Important: Correspondance avec la base de données
Le chemin dans S3 doit correspondre au `videoId` dans votre table `contenu`:
```sql
-- Si le fichier est: s3://wouritv-premium-videos/premium/film-1.mp4
-- Alors dans la DB:
UPDATE contenu SET videoId = 'premium/film-1.mp4' WHERE id = 123;
  │   ├── film-1.mp4
  │   ├── film-2.mp4
  │   └── serie-1/
  │       ├── episode-1.mp4
  │       └── episode-2.mp4
```

### Upload avec AWS CLI
```bash
# Installer AWS CLI
brew install awscli  # sur macOS

# Configurer AWS CLI
aws configure

# Uploader une vidéo
aws s3 cp film-1.mp4 s3://votre-bucket/premium/film-1.mp4
```

## 4. Tester la configuration

##Chemin S3 de la vidéo (stocké dans le champ videoId de la table contenu)
S3_PATH="premium/film-1.mp4"

# Appeler la Edge Function pour obtenir une URL signée
curl -X POST https://efpkxqfqlhzfvwpmejfp.supabase.co/functions/v1/generate-signed-url \
  -H "Authorization: Bearer VOTRE_TOKEN_JWT" \
  -H "Content-Type: application/json" \
  -d "{\"movieId\":\"123\",\"s3Path\":\"$S3_PATHs/v1/generate-signed-url \
  -H "Authorization: Bearer VOTRE_TOKEN_JWT" \
  -H "Content-Type: application/json" \
  -d "{\"movieId\":\"123\",\"cloudFrontUrl\":\"$CLOUDFRONT_URL\"}"

# Réponse attendue :
# {
#   "signedUrl": "https://d1234567890.cloudfront.net/premium/film-1.mp4?Policy=...&Signature=...&Key-Pair-Id=...",
#   "expiresAt": "2026-02-07T18:30:00.000Z"
# }
```

### Test depuis l'app Flutter

```dart
// Dans votre base de données, créer un film premium
// Table: contenu
// Champs:
//   - videoId: "https://d1234567890.cloudfront.net/premium/film-1.mp4"
//   - paiement: "OUI"
//   - prix: 5.99

// Table: liste (après achat)
// Champs:
//   - userId: "uuid-de-l-utilisateur"
//   - movieId: "123"
//   - achat: true
//   - expirationDate: null (ou date pour location)
```

## 5. Structure de la base de données

### Table `contenu` - Films premium
```sql
-- Le videoId contient maintenant le CHEMIN S3, pas l'URL CloudFront complète
UPDATE contenu 
SET 
  videoId = 'premium/film-1.mp4',  -- Chemin dans le bucket S3
  paiement = 'OUI',
  prix = 5.99
WHERE id = 123;

-- Exemples de chemins S3 valides:
-- 'premium/film-1.mp4'
-- 'series/saison1/episode1.mp4'
-- 'documentaires/nature.m3u8'
```

### Table `liste` - Vérifier les achats
```sql
-- Vérifier si un user a acheté un film
SELECT achat, expirationDate 
FROM liste 
WHERE userId = 'uuid-user' 
  AND movieId = '123' 
### ✅ Sécurité implémentée
- Les URLs CloudFront signées expirent après 4 heures
- La Edge Function vérifie que l'user a bien acheté le film (table `liste`)
- La Edge Function vérifie l'expiration (pour les locations)
- Les vidéos premium ne sont pas listées publiquement
- Le bucket S3 bloque tout accès public (uniquement CloudFront via OAI)

### ⚠️ Points critiques de sécurité
- **Ne JAMAIS** exposer la clé privée CloudFront dans le code client
- **Ne JAMAIS** générer les URLs signées côté client
- **Toujours** passer par la Edge Function pour générer les URLs
- **Ne PAS** stocker de credentials AWS dans le code (S3, CloudFront, etc.)

### 🔐 Credentials nécessaires et où ils sont utilisés

| Credential | Où? | Pourquoi? |
|------------|-----|-----------|
| AWS Access Key/Secret | AWS CLI (votre ordinateur) | Upload vidéos sur S3 |
| CLOUDFRONT_DOMAIN | Supabase Edge Function | Construire l'URL CloudFront |
| CLOUDFRONT_KEY_PAIR_ID | Supabase Edge Function | Signer les URLs |
| CLOUDFRONT_PRIVATE_KEY | Supabase Edge Function | Signer les URLs |
| ~~S3 Credentials~~ | ❌ Jamais dans le code | CloudFront accède via OAI |

### 📊 Monitoring
- Activer CloudFront Access Logs (stockés dans S3)
- Activer CloudWatch Logs pour la Edge Function
- Surveiller les tentatives d'accès non autorisée
   ```sql
   UPDATE contenu SET 
     videoId = 'https://VOTRE_CLOUDFRONT.cloudfront.net/premium/film-test.mp4',
     paiement = 'OUI',
     prix = 4.99
   WHERE id = 999;
   ```

2. **Simuler un achat**
   ```sql
   INSERT INTO liste (userId, movieId, achat, expirationDate, operationDate)
   VALUES ('uuid-de-votre-user', '999', true, null, NOW());
   ```

3. **Tester dans l'app**
   - Ouvrir le film premium
   - L'app détecte l'URL CloudFront
   - Appelle `premiumVideoService.getSignedUrl()`
   - Affiche le message "Lecteur premium bientôt disponible" (en attendant l'implémentation)

## 7. Prochaine étape : Lecteur vidéo CloudFront

Pour lire les vidéos CloudFront, il faudra :

1. Ajouter un package comme `video_player` ou `better_player`
   ```yaml
   dependencies:
     video_player: ^2.8.2
   ```

2. Modifier `VideoPlayerScreen` pour supporter les deux types de vidéos :
   - YouTube : utiliser `youtube_player_flutter`
   - CloudFront : utiliser `video_player`

3. Gérer la transition entre les deux lecteurs selon l'URL

## 8. Sécurité et bonnes pratiques

- ✅ Les URLs signées expirent après 4 heures
- ✅ La Edge Function vérifie que l'user a bien acheté le film
- ✅ La Edge Function vérifie l'expiration (pour les locations)
- ✅ Les vidéos premium ne sont pas listées publiquement
- ⚠️ Ne jamais exposer la clé privée CloudFront dans le code
- ⚠️ Toujours passer par la Edge Function pour générer les URLs
- ⚠️ Activer CloudWatch Logs pour surveiller les accès

## 9. Debugging

### Logs Supabase Edge Function
```bash
supabase functions logs generate-signed-url --project-ref efpkxqfqlhzfvwpmejfp --follow
```

### Logs CloudFront
1. Allez dans votre distribution CloudFront
2. **Edit** → **Logging** : ON
3. Sélectionnez un bucket S3 pour stocker les logs

### Vérifier les secrets
```bash
supabase secrets list --project-ref efpkxqfqlhzfvwpmejfp
```

## 10. Troubleshooting

### Erreur "CloudFront credentials not configured"
→ Vérifier que les secrets sont bien configurés dans Supabase

### Erreur "Film non acheté ou accès refusé"
→ Vérifier la table `liste` avec la requête SQL du point 5

### Erreur "Invalid signature"
→ Vérifier que la clé privée est bien formatée (avec `\n` préservés)

### Vidéo ne charge pas
→ Vérifier que l'URL CloudFront est accessible (tester dans un navigateur avec une URL signée)
