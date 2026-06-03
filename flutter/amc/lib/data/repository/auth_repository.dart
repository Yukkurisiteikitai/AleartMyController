import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Google サインイン + Supabase 認証（Android: AuthRepository 相当、§4.1）。
///
/// 同一の Google サインインから 2 つを取り出す:
/// - Supabase 用 idToken → `auth.signInWithIdToken`
/// - Google Calendar 用 AuthClient → `extension_google_sign_in_as_googleapis_auth`
class AuthRepository {
  AuthRepository(this._googleSignIn, this._supabase);

  final GoogleSignIn _googleSignIn;

  /// Supabase 未初期化なら null（クラウド機能を呼んだ時のみエラーにする）。
  final SupabaseClient? _supabase;

  /// クラウド操作で非null クライアントが必要な箇所のガード。
  SupabaseClient _requireClient() {
    final client = _supabase;
    if (client == null) {
      throw StateError(
        'Supabase が初期化されていません。SUPABASE_URL / SUPABASE_ANON_KEY を '
        '--dart-define で設定してください。',
      );
    }
    return client;
  }

  bool isSupabaseAuthenticated() =>
      _supabase?.auth.currentSession != null;

  String? currentSupabaseUserId() => _supabase?.auth.currentUser?.id;

  Future<GoogleSignInAccount?> signInSilently() =>
      _googleSignIn.signInSilently();

  /// Google サインイン → Supabase サインイン → profiles upsert。
  /// 失敗時は例外を投げる（呼び出し元で catch してエラー表示する）。
  Future<void> signInWithSupabase() async {
    final supabase = _requireClient();
    final account = _googleSignIn.currentUser ??
        await _googleSignIn.signInSilently() ??
        await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Google sign-in was cancelled');
    }
    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw StateError(
        'Google idToken is null. serverClientId / Web client ID の設定を確認してください。',
      );
    }
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    await _upsertProfile(supabase, account);
  }

  /// Google Calendar 用の認証済みクライアント（googleapis に渡す）。
  Future<AuthClient?> calendarAuthClient() async {
    if (_googleSignIn.currentUser == null) {
      await _googleSignIn.signInSilently();
    }
    return _googleSignIn.authenticatedClient();
  }

  Future<void> _upsertProfile(
    SupabaseClient supabase,
    GoogleSignInAccount account,
  ) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'google_subject': account.id,
        if (account.displayName != null) 'display_name': account.displayName,
        if (account.photoUrl != null) 'avatar_url': account.photoUrl,
      });
    } catch (_) {
      // プロフィール upsert 失敗はサインイン自体を失敗させない。
    }
  }

  /// 既定の GoogleSignIn スコープ（Calendar 書き込み + Supabase 用 email）。
  static List<String> get defaultScopes => <String>[
        'email',
        gcal.CalendarApi.calendarEventsScope,
      ];
}
