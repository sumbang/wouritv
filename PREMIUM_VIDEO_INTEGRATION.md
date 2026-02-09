# Intégration des Vidéos Premium CloudFront

## Vue d'ensemble

Architecture complète pour gérer les vidéos premium hébergées sur AWS CloudFront avec URLs signées.

**Note importante** : Utilisation de la table `liste` existante pour gérer les achats via le champ `achat` (bool).

## 1. Backend Supabase

### Table `liste` (existante)

Structure de la table déjà en place :

```sql
-- La table liste contient déjà :
-- userId: UUID
-- movieId: TEXT
-- achat: BOOLEAN (true pour les achats)
-- expirationDate: TIMESTAMP (pour locations temporaires)
-- operationDate: TIMESTAMP

-- Créer un index pour performances si pas déjà fait
CREATE INDEX IF NOT EXISTS idx_liste_achat ON liste(userId, movieId, achat);
```

### Supabase Edge Function

Créer `supabase/functions/generate-signed-url/index.ts` :

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getSignedUrl } from "https://esm.sh/@aws-sdk/cloudfront-signer@3"

serve(async (req) => {
  try {
    const { contentId, userId } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    
    // 1. Récupérer le contenu et le film associé
    const { data: content, error: contentError } = await supabase
      .from('contenus')
      .select('id, lien, title, movies(id, paiement, prix)')
      .eq('id', contentId)
      .single()
    
    if (contentError || !content) {
      return new Response(
        JSON.stringify({ error: 'Contenu non trouvé' }),
        { status: 404 }
      )
    }
    
    // 2. Vérifier l'accès pour les films premium
    const isPremium = content.movies.paiement === 'OUI' && content.movies.prix > 0
    
    if (isPremium) {
      // Vérifier dans la table liste si l'utilisateur a acheté
      const { data: purchase } = await supabase
        .from('liste')
        .select('achat, expirationDate')
        .eq('userId', userId)
        .eq('movieId', content.movies.id)
        .eq('achat', true)
        .maybeSingle()
      
      if (!purchase) {
        return new Response(
          JSON.stringify({ error: 'Achat requis pour accéder à ce contenu' }),
          { status: 403 }
        )
      }
      
      // Vérifier l'expiration si définie
      if (purchase.expirationDate) {
        const expiration = new Date(purchase.expirationDate)
        if (new Date() > expiration) {
          return new Response(
            JSON.stringify({ error: 'Votre accès à ce contenu a expiré' }),
            { status: 403 }
          )
        }
      }
    }
    
    // 3. Générer l'URL signée CloudFront
    const cloudFrontUrl = content.lien
    const cloudFrontKeyPairId = Deno.env.get('CLOUDFRONT_KEY_PAIR_ID')!
    const cloudFrontPrivateKey = Deno.env.get('CLOUDFRONT_PRIVATE_KEY')!
    
    const signedUrl = getSignedUrl({
      url: cloudFrontUrl,
      keyPairId: cloudFrontKeyPairId,
      privateKey: cloudFrontPrivateKey,
      dateLessThan: new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString(), // 4 heures
    })
    
    return new Response(
      JSON.stringify({ url: signedUrl }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Erreur:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
})
```

### Déployer la fonction

```bash
supabase functions deploy generate-signed-url

# Définir les secrets
supabase secrets set CLOUDFRONT_KEY_PAIR_ID=APKAXXXXXX
supabase secrets set CLOUDFRONT_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----..."
```

## 2. Frontend Flutter

### Services créés

✅ `lib/data/api/premium_video_service.dart` - Déjà créé

### Modifications dans VideoPlayerScreen

Dans `lib/presentation/screen/movie/video_player_screen.dart`, modifier `_initializePlayer` :

```dart
Future<void> _initializePlayer() async {
  setState(() => _isLoading = true);

  try {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    
    String videoUrl = widget.content.lien;
    
    // Si le contenu est premium (CloudFront), récupérer l'URL signée
    if (videoUrl.contains('cloudfront.net')) {
      if (user == null) {
        throw Exception('Connexion requise pour accéder à ce contenu');
      }
      
      developer.log('🔐 Contenu premium détecté', name: 'VideoPlayerScreen');
      
      final premiumService = ref.read(premiumVideoServiceProvider);
      videoUrl = await premiumService.getSignedUrl(
        contentId: widget.content.id.toString(),
        userId: user.id,
      );
      
      developer.log('✅ URL signée CloudFront obtenue', name: 'VideoPlayerScreen');
    }
    
    // Initialiser le controller avec l'URL (YouTube ou CloudFront)
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')
          ? YoutubePlayerController.convertUrlToId(videoUrl) ?? ''
          : '',
      params: YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableJavaScript: true,
      ),
    );
    
    // Ou utiliser video_player pour CloudFront
    if (!videoUrl.contains('youtube')) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      await _videoController!.play();
    }
    
    setState(() => _isLoading = false);
  } catch (e) {
    developer.log('❌ Erreur: $e', name: 'VideoPlayerScreen');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    }
  }
}
```

### Gestion du paiement (intégration future)

Après un paiement réussi, enregistrer l'achat dans la table `liste` :

```dart
Future<void> _processPurchase(String movieId, {DateTime? expirationDate}) async {
  final authService = ref.read(authServiceProvider);
  final user = authService.currentUser;
  
  if (user == null) return;
  
  // 1. Traiter le paiement (Stripe, PayPal, etc.)
  // ...
  
  // 2. Enregistrer l'achat dans la table liste
  final premiumService = ref.read(premiumVideoServiceProvider);
  await premiumService.recordPurchase(
    movieId: movieId,
    userId: user.id,
    expirationDate: expirationDate, // null pour achat permanent, date pour location
  );
  
  // Le film sera automatiquement visible dans "Ma liste" car achat=true
}
```

### Exemple d'achat avec expiration (location 48h)

```dart
// Location 48 heures
await premiumService.recordPurchase(
  movieId: movieId,
  userId: user.id,
  expirationDate: DateTime.now().add(Duration(hours: 48)),
);

// Achat définitif (pas d'expiration)
await premiumService.recordPurchase(
  movieId: movieId,
  userId: user.id,
  expirationDate: null,
);
```

## 3. Configuration CloudFront

### Créer une distribution CloudFront

1. Dans AWS Console → CloudFront
2. Create Distribution
3. Origin Domain: Ton bucket S3 avec les vidéos
4. **Restrict Viewer Access**: Yes
5. **Trusted Signers**: Self (utiliser ton compte AWS)
6. **Key Group**: Créer un key group avec une paire de clés

### Générer une paire de clés CloudFront

```bash
# Dans AWS Console → CloudFront → Key Management
# Créer une paire de clés publique/privée
# Télécharger la clé privée (une seule fois !)
```

## 4. Variables d'environnement

Dans Supabase Dashboard → Project Settings → Edge Functions :

```
CLOUDFRONT_KEY_PAIR_ID=APKAXXXXXX
CLOUDFRONT_PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----
MIIEXXX...
-----END RSA PRIVATE KEY-----
```

## 5. Tests

### Test d'achat
```dart
// Dans un bouton "Acheter" sur MovieDetailScreen
final premiumService = ref.read(premiumVideoServiceProvider);
await premiumService.recordPurchase(
  movieId: widget.movie.id,
  userId: user!.id,
);
```

### Test de lecture
```dart
// Le VideoPlayerScreen détectera automatiquement CloudFront
// et demandera l'URL signée
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => VideoPlayerScreen(
      content: content,
      movieTitle: movie.title,
      movieId: int.parse(movie.id),
    ),
  ),
);
```

## 6. Sécurité

- ✅ URLs signées expirent après 4h
- ✅ Vérification d'achat côté serveur
- ✅ Row Level Security sur Supabase
- ✅ Clés privées stockées dans secrets Supabase
- ✅ Pas de clés dans le code client

## 7. Flux complet

```
1. User achète film premium (ou location)
   ↓
2. Paiement traité (Stripe/PayPal)
   ↓
3. Mise à jour table liste : achat=true, expirationDate (optionnel)
   ↓
4. Film visible automatiquement dans "Ma liste"
   ↓
5. User clique sur "Lire"
   ↓
6. App détecte URL CloudFront
   ↓
7. App demande URL signée à Supabase Function
   ↓
8. Function vérifie achat dans table liste + expiration
   ↓
9. Function génère URL signée (expire 4h)
   ↓
10. Lecture de la vidéo CloudFront
```

## 8. Prochaines étapes

1. ✅ Vérifier que la table `liste` a les champs `achat` et `expirationDate`
2. ✅ Déployer la fonction Edge `generate-signed-url`
3. ✅ Configurer CloudFront avec clés signées
4. ✅ Intégrer un système de paiement (Stripe, PayPal, etc.)
5. Tester le flux complet
6. Ajouter des analytics de visionnage

## 9. Différences Achat vs Location

### Achat permanent
```dart
await premiumService.recordPurchase(
  movieId: movieId,
  userId: user.id,
  expirationDate: null, // Pas d'expiration
);
```

### Location temporaire
```dart
await premiumService.recordPurchase(
  movieId: movieId,
  userId: user.id,
  expirationDate: DateTime.now().add(Duration(days: 7)), // 7 jours
);
```

La vérification de l'expiration se fait automatiquement dans `hasUserPurchased()` et dans la Edge Function.

---

**Note** : Cette architecture utilise la table `liste` existante avec le champ `achat=true` pour identifier les achats, ce qui évite de créer une table séparée et maintient tout centralisé.

## 9. Dépendances Flutter à ajouter

```yaml
# pubspec.yaml
dependencies:
  video_player: ^2.8.0  # Pour CloudFront
  youtube_player_iframe: ^5.1.0  # Pour YouTube (déjà installé)
```

---

**Note** : Cette architecture garantit que seuls les utilisateurs ayant acheté un film premium peuvent accéder aux vidéos CloudFront, avec des URLs temporaires sécurisées.
