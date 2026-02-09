# Architecture CloudFront pour Vidéos Premium

## 📐 Schéma complet de l'architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUX COMPLET                             │
└─────────────────────────────────────────────────────────────────┘

1. UPLOAD DES VIDÉOS (Une seule fois)
   ┌──────────────┐   AWS CLI    ┌─────────────────┐
   │ Votre PC     │──────────────>│ S3 Bucket       │
   │ (Admin)      │   avec IAM    │ (Private)       │
   └──────────────┘   credentials └─────────────────┘
                                   │
                                   │ Origin Access Identity (OAI)
                                   │ (pas de credentials dans code)
                                   ▼
                                  ┌─────────────────┐
                                  │ CloudFront      │
                                  │ Distribution    │
                                  └─────────────────┘

2. LECTURE D'UNE VIDÉO PREMIUM (À chaque visionnage)
   
   ┌──────────────┐
   │ Flutter App  │
   │ (User)       │
   └──────┬───────┘
          │ 1. Click "Lire" sur film premium
          │    (videoId = "premium/film-1.mp4")
          │
          ▼
   ┌──────────────┐
   │VideoPlayer   │
   │Screen        │ 2. Détecte chemin S3 (contient "/")
   └──────┬───────┘
          │ 3. Vérifie auth user
          │
          ▼
   ┌──────────────┐
   │Premium       │
   │VideoService  │ 4. Appelle getSignedUrl(movieId, s3Path)
   └──────┬───────┘
          │
          │ 5. HTTP POST + JWT token
          ▼
   ┌─────────────────────────────────────────┐
   │ Supabase Edge Function                  │
   │ "generate-signed-url"                   │
   │                                         │
   │ Secrets (env vars):                     │
   │ - CLOUDFRONT_DOMAIN                     │
   │ - CLOUDFRONT_KEY_PAIR_ID                │
   │ - CLOUDFRONT_PRIVATE_KEY                │
   │                                         │
   │ Steps:                                  │
   │ 6. Vérifie JWT token                    │
   │ 7. Vérifie achat (table liste)          │
   │ 8. Vérifie expiration (si location)     │
   │ 9. Construit URL CloudFront              │
   │    https://{DOMAIN}/{s3Path}            │
   │ 10. Signe URL avec RSA signature        │
   └──────┬──────────────────────────────────┘
          │
          │ 11. Retourne signed URL
          ▼
   ┌──────────────┐
   │ Flutter App  │
   │              │ 12. Reçoit URL signée
   │              │     (valide 4h)
   └──────┬───────┘
          │
          │ 13. TODO: Utiliser video_player
          │     pour lire l'URL CloudFront
          ▼
   ┌─────────────────┐
   │ CloudFront      │ 14. Valide signature
   │                 │ 15. Fetch vidéo depuis S3
   └────────┬────────┘
            │
            │ 16. Stream vidéo
            ▼
   ┌──────────────┐
   │ User regarde │
   │ la vidéo     │
   └──────────────┘
```

## 🔑 Credentials et leur utilisation

### AWS IAM User (Pour upload S3 uniquement)
```bash
# Configuration locale sur votre PC
aws configure
# Access Key: AKIA...
# Secret Key: ...
# Region: eu-west-1
```

**Utilisé pour**: Uploader les vidéos sur S3 depuis votre ordinateur  
**PAS utilisé dans**: Code Flutter, Edge Function, ou app mobile  
**Permissions requises**: `s3:PutObject` sur le bucket S3

---

### CloudFront Distribution
**Créé dans**: AWS Console → CloudFront  
**Configuration**:
- Origin: Bucket S3 avec OAI (Origin Access Identity)
- Behavior: Restrict Viewer Access = Yes
- Trusted Key Groups: Votre key group avec la clé publique

**Résultat**: Domaine CloudFront (ex: `d1234567890.cloudfront.net`)

---

### CloudFront Key Pair (Pour signer les URLs)
```bash
# Générer la paire de clés
openssl genrsa -out cloudfront-private-key.pem 2048
openssl rsa -pubout -in cloudfront-private-key.pem -out cloudfront-public-key.pem
```

**Clé publique** (`cloudfront-public-key.pem`):
- Uploadée dans AWS Console → CloudFront → Key Management
- Ajoutée à un Key Group
- Attachée à la distribution CloudFront

**Clé privée** (`cloudfront-private-key.pem`):
- Stockée dans Supabase Secrets (`CLOUDFRONT_PRIVATE_KEY`)
- Utilisée par la Edge Function pour signer les URLs
- **JAMAIS** dans le code Flutter ou exposée publiquement

**Key Pair ID**:
- Visible dans AWS Console après création de la clé publique
- Format: `K2JCJMDEHXQW5F`
- Stocké dans Supabase Secrets (`CLOUDFRONT_KEY_PAIR_ID`)

---

### Supabase Edge Function Secrets
```bash
# Ces 3 secrets sont TOUT ce dont vous avez besoin dans Supabase
supabase secrets set CLOUDFRONT_DOMAIN="d1234567890.cloudfront.net" --project-ref efpkxqfqlhzfvwpmejfp
supabase secrets set CLOUDFRONT_KEY_PAIR_ID="K2JCJMDEHXQW5F" --project-ref efpkxqfqlhzfvwpmejfp
supabase secrets set CLOUDFRONT_PRIVATE_KEY="$(cat cloudfront-private-key.pem)" --project-ref efpkxqfqlhzfvwpmejfp
```

---

## ❌ Ce dont vous N'AVEZ PAS besoin

### Dans le code Flutter
- ❌ AWS Access Key / Secret Key
- ❌ S3 Bucket Name
- ❌ S3 Region
- ❌ CloudFront Private Key
- ❌ CloudFront Distribution ID

### Dans la Edge Function
- ❌ AWS Access Key / Secret Key
- ❌ S3 Credentials
- ❌ CloudFront Distribution ID

## ✅ Checklist de configuration

### 1. AWS Configuration (une seule fois)
- [ ] Créer un bucket S3 privé (ex: `wouritv-premium-videos`)
- [ ] Créer une distribution CloudFront avec OAI pointant vers ce bucket
- [ ] Générer une paire de clés RSA (public/private)
- [ ] Uploader la clé publique dans CloudFront Key Management
- [ ] Créer un Key Group et l'attacher à la distribution
- [ ] Activer "Restrict Viewer Access" sur la distribution
- [ ] Noter le domaine CloudFront (ex: `d1234567890.cloudfront.net`)
- [ ] Noter le Key Pair ID (ex: `K2JCJMDEHXQW5F`)

### 2. Supabase Configuration
- [ ] Créer le fichier `supabase/functions/generate-signed-url/index.ts`
- [ ] Déployer la fonction: `supabase functions deploy generate-signed-url`
- [ ] Configurer les 3 secrets: DOMAIN, KEY_PAIR_ID, PRIVATE_KEY
- [ ] Tester avec cURL

### 3. Flutter Configuration
- [ ] PremiumVideoService déjà implémenté ✅
- [ ] VideoPlayerScreen détecte les chemins S3 ✅
- [ ] Provider configuré ✅
- [ ] TODO: Implémenter lecteur vidéo CloudFront (video_player package)

### 4. Base de données
- [ ] Table `liste` avec champs `achat`, `expirationDate` ✅
- [ ] Films premium avec `videoId` = chemin S3 (ex: `premium/film-1.mp4`)
- [ ] Films premium avec `paiement = 'OUI'` et `prix > 0`

### 5. Upload des vidéos
- [ ] Installer AWS CLI localement
- [ ] Configurer AWS CLI avec IAM user credentials
- [ ] Uploader les vidéos: `aws s3 cp video.mp4 s3://bucket/premium/video.mp4`
- [ ] Mettre à jour la table `contenu` avec le chemin S3

## 🔒 Sécurité: Pourquoi cette architecture est sûre

1. **Bucket S3 privé**: Aucun accès public, uniquement CloudFront via OAI
2. **URLs signées**: Expirent après 4h, nécessitent une signature cryptographique
3. **Vérification serveur**: La Edge Function vérifie l'achat avant de signer
4. **Clé privée sécurisée**: Stockée uniquement dans Supabase Secrets
5. **Pas de credentials client**: Le code Flutter n'a aucun credential AWS
6. **JWT Authentication**: Requiert un utilisateur Supabase authentifié

## 📝 Exemple de flux utilisateur

```
User non connecté → Voit film premium → Click "Lire"
→ Message: "Vous devez être connecté"

User connecté sans achat → Click "Lire"
→ Edge Function vérifie liste → Retourne error
→ Message: "Vous devez acheter ce contenu"

User connecté avec achat → Click "Lire"
→ Edge Function vérifie liste → Achat trouvé
→ Vérifie expiration → OK
→ Génère URL signée → Retourne au client
→ (TODO) Video player lit la vidéo CloudFront

User avec location expirée → Click "Lire"
→ Edge Function vérifie expirationDate → Expiré
→ Message: "Votre location a expiré"
```

## 🎯 Résumé en 3 points

1. **Upload** (Admin): AWS CLI + IAM credentials → S3 bucket privé
2. **Génération URL** (Runtime): Flutter app → Edge Function (avec secrets CloudFront) → URL signée
3. **Lecture** (User): URL signée → CloudFront (vérifie signature) → Stream depuis S3

**Aucun credential AWS n'est jamais exposé dans le code client ou les APIs publiques.**
