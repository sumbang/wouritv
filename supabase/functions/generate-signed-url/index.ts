import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Gérer les requêtes OPTIONS pour CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log('📥 Requête reçue');
    
    // Vérifier le secret partagé pour authentifier l'appel
    const functionSecret = Deno.env.get('FUNCTION_SECRET');
    const clientSecret = req.headers.get('x-function-secret') || req.headers.get('X-Function-Secret');
    
    console.log(`🔑 Secret attendu: ${functionSecret}`);
    console.log(`🔑 Secret reçu: ${clientSecret}`);
    console.log(`📋 Headers disponibles: ${JSON.stringify(Array.from(req.headers.entries()))}`);
    
    if (!clientSecret || clientSecret !== functionSecret) {
      console.log('❌ Secret invalide ou manquant');
      return new Response(
        JSON.stringify({ 
          error: 'Unauthorized: Invalid or missing secret',
          debug: {
            receivedSecret: clientSecret ? `${clientSecret.substring(0, 10)}...` : 'null',
            expectedSecret: functionSecret ? `${functionSecret.substring(0, 10)}...` : 'null'
          }
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    console.log('✅ Secret validé');

    // Récupérer les paramètres de la requête
    const { userId, movieId, s3Path } = await req.json();
    
    if (!userId || !movieId || !s3Path) {
      throw new Error('Missing userId, movieId or s3Path');
    }

    console.log(`✅ User ID reçu: ${userId}`);
    console.log(`✅ Movie ID: ${movieId}`);
    console.log(`✅ S3 Path: ${s3Path}`);

    // Récupérer les paramètres de la requête (movieId, s3Path déjà extraits)
    
    if (!movieId || !s3Path) {
      throw new Error('Missing movieId or s3Path');
    }

    // Construire l'URL CloudFront complète
    const cloudFrontDomain = Deno.env.get('CLOUDFRONT_DOMAIN');
    console.log(`🔧 CloudFront Domain: ${cloudFrontDomain ? 'Configuré' : 'MANQUANT'}`);
    if (!cloudFrontDomain) {
      throw new Error('CLOUDFRONT_DOMAIN not configured');
    }
    
    // Nettoyer le chemin S3 (enlever le slash de début s'il existe)
    const cleanPath = s3Path.startsWith('/') ? s3Path.substring(1) : s3Path;
    const cloudFrontUrl = `https://${cloudFrontDomain}/${cleanPath}`;
    
    console.log(`📹 Génération URL pour: ${cloudFrontUrl}`);

    // Utiliser SERVICE_ROLE_KEY pour accéder à la base de données
    console.log('🔍 Vérification achat dans la base de données...');
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Vérifier que l'utilisateur a acheté ce film dans la table liste
    const { data: purchase, error: purchaseError } = await supabaseAdmin
      .from('liste')
      .select('achat, expirationDate')
      .eq('userId', userId)
      .eq('movieId', movieId)
      .eq('achat', true)
      .maybeSingle();

    console.log(`📊 Résultat requête DB - Error: ${purchaseError ? purchaseError.message : 'none'}, Data: ${purchase ? 'found' : 'not found'}`);

    if (purchaseError) {
      throw new Error(`Database error: ${purchaseError.message}`);
    }

    if (!purchase) {
      return new Response(
        JSON.stringify({ error: 'Film non acheté ou accès refusé' }),
        { 
          status: 403, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    // Vérifier si l'achat n'a pas expiré (pour les locations)
    if (purchase.expirationDate) {
      const expirationDate = new Date(purchase.expirationDate);
      if (new Date() > expirationDate) {
        return new Response(
          JSON.stringify({ error: 'Votre location a expiré' }),
          { 
            status: 403, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        );
      }
    }

    // Générer l'URL signée CloudFront
    console.log('🔐 Début génération signature CloudFront...');
    const keyPairId = Deno.env.get('CLOUDFRONT_KEY_PAIR_ID')!;
    const privateKey = Deno.env.get('CLOUDFRONT_PRIVATE_KEY')!;
    
    console.log(`🔧 KeyPairId: ${keyPairId ? 'Configuré' : 'MANQUANT'}`);
    console.log(`🔧 PrivateKey: ${privateKey ? 'Configuré' : 'MANQUANT'}`);
    
    if (!keyPairId || !privateKey) {
      throw new Error('CloudFront credentials not configured');
    }

    // Calculer l'expiration (4 heures)
    const expirationTime = Math.floor(Date.now() / 1000) + (4 * 60 * 60);

    // Créer la policy pour CloudFront
    const policy = {
      Statement: [{
        Resource: cloudFrontUrl,
        Condition: {
          DateLessThan: {
            'AWS:EpochTime': expirationTime
          }
        }
      }]
    };

    const policyString = JSON.stringify(policy);
    const encoder = new TextEncoder();
    const policyBytes = encoder.encode(policyString);

    // Base64 encode (URL-safe)
    const base64Policy = btoa(String.fromCharCode(...policyBytes))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');

    // Signer la policy avec la clé privée CloudFront
    console.log('🔏 Import clé privée...');
    let privateKeyPem = privateKey.replace(/\\n/g, '\n');
    
    // Ajouter les headers PEM si absents
    if (!privateKeyPem.includes('BEGIN PRIVATE KEY')) {
      console.log('⚠️ Headers PEM manquants, ajout automatique...');
      privateKeyPem = `-----BEGIN PRIVATE KEY-----\n${privateKeyPem}\n-----END PRIVATE KEY-----`;
    }
    
    const key = await crypto.subtle.importKey(
      'pkcs8',
      pemToArrayBuffer(privateKeyPem),
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-1'
      },
      false,
      ['sign']
    );

    console.log('✍️ Signature de la policy...');
    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      key,
      policyBytes
    );

    // Base64 encode signature (URL-safe)
    const base64Signature = btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');

    // Construire l'URL signée
    const separator = cloudFrontUrl.includes('?') ? '&' : '?';
    const signedUrl = `${cloudFrontUrl}${separator}Policy=${base64Policy}&Signature=${base64Signature}&Key-Pair-Id=${keyPairId}`;

    console.log('✅ URL signée générée avec succès!');

    return new Response(
      JSON.stringify({ 
        signedUrl,
        expiresAt: new Date(expirationTime * 1000).toISOString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    console.error('❌ Error generating signed URL:', error);
    console.error('❌ Error stack:', error.stack);
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});

// Fonction utilitaire pour convertir PEM en ArrayBuffer
function pemToArrayBuffer(pem: string): ArrayBuffer {
  // Supporter les deux formats : PKCS8 et RSA
  const pemHeaderPKCS8 = '-----BEGIN PRIVATE KEY-----';
  const pemFooterPKCS8 = '-----END PRIVATE KEY-----';
  const pemHeaderRSA = '-----BEGIN RSA PRIVATE KEY-----';
  const pemFooterRSA = '-----END RSA PRIVATE KEY-----';
  
  console.log(`🔍 PEM brut (premiers 100 chars): ${pem.substring(0, 100)}`);
  console.log(`🔍 PEM brut (longueur): ${pem.length}`);
  
  // Nettoyer la clé PEM: gérer à la fois le format multi-lignes et le format \n échappé
  let cleanedPem = pem;
  
  // Si la clé contient des \n littéraux (stockés comme \\n dans le secret), les remplacer par de vrais sauts de ligne
  if (cleanedPem.includes('\\n')) {
    console.log('🔧 Remplacement des \\\\n par de vrais sauts de ligne');
    cleanedPem = cleanedPem.replace(/\\n/g, '\n');
  }
  
  // Détecter le format
  let pemHeader = pemHeaderPKCS8;
  let pemFooter = pemFooterPKCS8;
  
  if (cleanedPem.includes(pemHeaderRSA)) {
    console.log('📝 Format détecté: RSA PRIVATE KEY');
    pemHeader = pemHeaderRSA;
    pemFooter = pemFooterRSA;
  } else {
    console.log('📝 Format détecté: PRIVATE KEY (PKCS8)');
  }
  
  // Extraire le contenu entre les headers
  const startIndex = cleanedPem.indexOf(pemHeader);
  const endIndex = cleanedPem.indexOf(pemFooter);
  
  console.log(`🔍 Start index: ${startIndex}, End index: ${endIndex}`);
  
  if (startIndex === -1 || endIndex === -1) {
    throw new Error(`Invalid PEM format: missing header or footer. Found: ${cleanedPem.substring(0, 50)}`);
  }
  
  let pemContents = cleanedPem.substring(
    startIndex + pemHeader.length,
    endIndex
  );
  
  console.log(`🔍 Contenu PEM avant nettoyage (longueur): ${pemContents.length}`);
  console.log(`🔍 Contenu PEM avant nettoyage (premiers 50 chars): ${pemContents.substring(0, 50)}`);
  
  // Nettoyer: enlever tous les espaces, tabs, retours à la ligne, retours chariot
  pemContents = pemContents.replace(/[\s\r\n\t]/g, '');
  
  console.log(`🔍 Contenu PEM après nettoyage (longueur): ${pemContents.length}`);
  console.log(`🔍 Contenu PEM après nettoyage (premiers 50 chars): ${pemContents.substring(0, 50)}`);
  
  if (!pemContents) {
    throw new Error('PEM content is empty after cleaning');
  }
  
  // Décoder le base64
  try {
    const binaryString = atob(pemContents);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    console.log('✅ Clé PEM décodée avec succès');
    return bytes.buffer;
  } catch (e) {
    console.error(`❌ Erreur décodage base64: ${e.message}`);
    console.error(`❌ Contenu qui a échoué (50 premiers chars): ${pemContents.substring(0, 50)}`);
    throw e;
  }
}
