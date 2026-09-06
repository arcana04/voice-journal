import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/db_service.dart';

/// アカウント連携エラーの理由。UI側でメッセージ出し分けに使う。
class AccountException implements Exception {
  final AccountErrorReason reason;
  // 表示用にはreasonで大雑把に丸めるが、調査中はこちらで元の例外の
  // code/messageを確認できるようにしておく。
  final Object? cause;
  AccountException(this.reason, [this.cause]);

  @override
  String toString() => 'AccountException($reason, cause: $cause)';
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

  /// [credentialProvider]が返すクレデンシャルで認証する。現在が匿名ユーザー
  /// ならまずそのアカウントへリンクを試み（uidが変わらないため既存のPro状態・
  /// 利用回数トラッキングはそのまま引き継がれる）、そのクレデンシャルが既に
  /// 別の既存アカウントに紐付いている場合（2台目の端末で同じGoogle/Apple
  /// アカウントを選んだ場合など）は、そちらの既存アカウントへのサインインに
  /// フォールバックする。戻り値は最終的なuid。
  ///
  /// クレデンシャルを呼び出し元から関数として受け取るのは、Appleの
  /// クレデンシャルはリプレイ対策のnonceを含んでおり、一度
  /// linkWithCredentialに使うとFirebase側でそのnonceが消費済み扱いになる
  /// ため——同じインスタンスをフォールバックのsignInWithCredentialに使い回すと
  /// missing-or-invalid-nonce（"Duplicate credential received"）で必ず失敗
  /// する。フォールバック時は[credentialProvider]を呼び直して新しい
  /// クレデンシャルを取得する。
  Future<String> signInWithCredential(
    Future<AuthCredential> Function() credentialProvider,
  ) async {
    try {
      final credential = await credentialProvider();
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
        final freshCredential = await credentialProvider();
        final result = await FirebaseAuth.instance.signInWithCredential(
          freshCredential,
        );
        notifyListeners();
        return result.user!.uid;
      }
    } on FirebaseAuthException catch (e) {
      throw AccountException(_reasonFor(e), e);
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

  /// アカウントと紐づく全データ（Firestoreの記録、Storageの写真・動画、端末
  /// ローカルのSQLite）を完全に削除する。[signOut]と違い元に戻せない。App
  /// Storeガイドライン5.1.1(v)（アカウント作成を提供するアプリはアプリ内での
  /// 削除手段も必須）への対応。サーバー側の削除（Cloud Function
  /// `deleteAccount`、Firebase Authのユーザー本体も含めて消す）が成功した後に
  /// のみローカルデータを消す — 途中でネットワークエラーなどが起きた場合に、
  /// サーバーは消えていないのにローカルだけ消えてしまう事態を避けるため。
  /// 成功後は新しい匿名セッションを再確立する。戻り値は新しい匿名uid。
  Future<String> deleteAccount() async {
    try {
      await FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('deleteAccount').call();
    } on FirebaseFunctionsException catch (e) {
      throw AccountException(
        e.code == 'unavailable' || e.code == 'deadline-exceeded'
            ? AccountErrorReason.networkError
            : AccountErrorReason.unknown,
        e,
      );
    }
    await DbService.instance.wipeAllLocalData();
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
