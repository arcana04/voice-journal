import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// アカウント連携エラーの理由。UI側でメッセージ出し分けに使う。
class AccountException implements Exception {
  final AccountErrorReason reason;
  // TODO(debug): 原因切り分け用に元のFirebaseAuthExceptionの内容を保持している。
  // 原因特定後、debugDetailごと削除すること。
  final String? debugDetail;
  AccountException(this.reason, [this.debugDetail]);

  @override
  String toString() => 'AccountException($reason, $debugDetail)';
}

enum AccountErrorReason { networkError, unknown }

/// Google/Appleサインインを管理する。端末は起動時から常にFirebase匿名認証で
/// サインインしている前提（[AuthService]）で、その匿名ユーザーをGoogle/Apple
/// アカウントへ昇格（初回リンク）、または同じアカウントで既に登録済みの
/// 別ユーザーへの切り替え（2台目以降の端末など）を行う。
class AccountStore extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSub;

  AccountStore() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  bool get isSignedIn {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous;
  }

  String? get email => FirebaseAuth.instance.currentUser?.email;

  /// サインイン中のアカウントを表す表示名。Apple の「メールを非公開」選択時など
  /// emailが取れない場合はdisplayNameにフォールバックする。
  String get displayLabel {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email ?? user?.displayName ?? '';
  }

  AccountErrorReason _reasonFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return AccountErrorReason.networkError;
      default:
        return AccountErrorReason.unknown;
    }
  }

  /// [credential]で認証する。現在が匿名ユーザーならまずそのアカウントへ
  /// リンクを試み（uidが変わらないため既存のPro状態・利用回数トラッキングは
  /// そのまま引き継がれる）、そのクレデンシャルが既に別の既存アカウントに
  /// 紐付いている場合（2台目の端末で同じGoogle/Appleアカウントを選んだ場合
  /// など）は、そちらの既存アカウントへのサインインにフォールバックする。
  /// 戻り値は最終的なuid。
  Future<String> signInWithCredential(AuthCredential credential) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !user.isAnonymous) {
        final result = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        notifyListeners();
        return result.user!.uid;
      }
      try {
        final result = await user.linkWithCredential(credential);
        notifyListeners();
        return result.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use' &&
            e.code != 'email-already-in-use') {
          rethrow;
        }
        final result = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        notifyListeners();
        return result.user!.uid;
      }
    } on FirebaseAuthException catch (e) {
      throw AccountException(_reasonFor(e), '${e.code}: ${e.message}');
    }
  }

  Future<AuthCredential> googleCredential() => _authService.signInWithGoogle();

  Future<AuthCredential> appleCredential() => _authService.signInWithApple();

  /// サインアウトしてすぐに新しい匿名セッションを再確立する。ローカルの
  /// 日記データは一切削除しない — ログアウトは同期を止めるだけで、
  /// データを消す操作ではない。戻り値は新しい匿名uid。
  Future<String> signOut() async {
    await FirebaseAuth.instance.signOut();
    final uid = await _authService.ensureSignedIn();
    notifyListeners();
    return uid;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
