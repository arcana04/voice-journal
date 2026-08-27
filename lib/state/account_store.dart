import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// アカウント作成/失敗理由をUI側で判別できるようにする例外。
class AccountException implements Exception {
  final AccountErrorReason reason;
  AccountException(this.reason);
}

enum AccountErrorReason {
  /// サインアップ時、そのメールが既に別アカウントに登録済み。
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  /// サインイン時、メール/パスワードが誤っている（存在しない・不一致）。
  invalidCredential,
  networkError,
  unknown,
}

/// メールアカウントのサインアップ/サインイン/サインアウトを管理する。
/// 端末は起動時から常にFirebase匿名認証でサインインしている前提
/// （[AuthService]）で、ここではその匿名ユーザーをメールアカウントへ昇格
/// （サインアップ）、または別の既存アカウントへの切り替え（サインイン）を行う。
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

  AccountErrorReason _reasonFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return AccountErrorReason.emailAlreadyInUse;
      case 'invalid-email':
        return AccountErrorReason.invalidEmail;
      case 'weak-password':
        return AccountErrorReason.weakPassword;
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return AccountErrorReason.invalidCredential;
      case 'network-request-failed':
        return AccountErrorReason.networkError;
      default:
        return AccountErrorReason.unknown;
    }
  }

  /// 現在の（匿名の）Firebaseユーザーをメール+パスワードのアカウントへ昇格する。
  /// uidは変わらないため、既存のPro状態・利用回数トラッキングはそのまま引き継がれる。
  /// 戻り値は新しいuid。
  Future<String> signUp(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _authService.ensureSignedIn();
        return await signUp(email, password);
      }
      final result = await user.linkWithCredential(credential);
      notifyListeners();
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AccountException(_reasonFor(e));
    }
  }

  /// 既存のメールアカウントへサインインする（別端末で作成済みのアカウントに
  /// この端末を接続する場合など）。uidは既存アカウントのものに切り替わる。
  Future<String> signIn(String email, String password) async {
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AccountException(_reasonFor(e));
    }
  }

  /// サインアウトしてすぐに新しい匿名セッションを再確立する。ローカルの
  /// 日記データは一切削除しない — ログアウトは同期を止めるだけで、
  /// データを消す操作ではない。戻り値は新しい匿名uid。
  Future<String> signOut() async {
    await FirebaseAuth.instance.signOut();
    final uid = await _authService.ensureSignedIn();
    notifyListeners();
    return uid;
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AccountException(_reasonFor(e));
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
