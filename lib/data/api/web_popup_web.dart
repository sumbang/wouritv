// Web implementation
import 'dart:html' as html;
import 'dart:developer' as developer;

typedef WindowBase = html.WindowBase;

html.WindowBase? oauthPopup;

void closeOAuthPopup() {
  if (oauthPopup != null && !oauthPopup!.closed!) {
    try {
      oauthPopup!.close();
      developer.log('✅ Popup OAuth fermée', name: 'SupabaseAuthService');
    } catch (e) {
      developer.log('⚠️ Impossible de fermer la popup: $e', name: 'SupabaseAuthService');
    }
    oauthPopup = null;
  } else {
    developer.log('ℹ️ Aucune popup OAuth à fermer', name: 'SupabaseAuthService');
  }
}
