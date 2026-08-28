import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// GoogleサインインをキャンセルしたときにUI側で（エラーダイアログを出さず）
/// 静かに無視できるようにするための例外。
class SignInCancelledException implements Exception {}

class AuthService {
  static bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    // Firebaseプロジェクトの「ウェブ」用OAuthクライアントID。IDトークンの
    // audienceをこれに合わせることで、Android/iOS共通でFirebase Authが
    // 受理できるIDトークンになる（Android/iOS個別のクライアントIDは
    // google-services.json / GoogleService-Info.plist側で解決される）。
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '447725635348-4sjd4q3qlelubsip8c96tmeomhp97sdd.apps.googleusercontent.com',
    );
    _googleInitialized = true;
  }

  /// Googleアカウントで認証し、Firebase用のクレデンシャルを返す。
  /// ユーザーが選択画面をキャンセルした場合は[SignInCancelledException]を投げる。
  Future<AuthCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'google-id-token-missing',
          message: 'Google sign-in did not return an ID token.',
        );
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw SignInCancelledException();
      }
      rethrow;
    }
  }

  /// Apple IDで認証し、Firebase用のクレデンシャルを返す。
  /// ユーザーが認証をキャンセルした場合は[SignInCancelledException]を投げる。
  Future<AuthCredential> signInWithApple() async {
    // リプレイ攻撃対策としてFirebaseが推奨するnonceの受け渡し
    // （生のnonceをFirebase側に渡し、そのSHA256ハッシュをApple側に渡す）。
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'apple-id-token-missing',
          message: 'Apple sign-in did not return an identity token.',
        );
      }
      return OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw SignInCancelledException();
      }
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  Future<String> ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    if (current != null) return current.uid;
    final credential = await auth.signInAnonymously();
    return credential.user!.uid;
  }
}
