import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/settings_service.dart';

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
  final SettingsService _settings = SettingsService();
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
  /// [beforeLocalWipe]は、端末に残ったローカルデータが実際にワイプされる前に
  /// 呼ばれる（別アカウントへの切り替えを検知した場合のみ）。予約済みの
  /// ローカル通知・カレンダー予定・Appleリマインダー・添付画像など、
  /// SQLite外に残る「前の持ち主」の副作用を後始末するために使う
  /// （[JournalStore.teardownAllLocalSideEffects]を渡す想定）。
  Future<String> signInWithCredential(
    Future<AuthCredential> Function() credentialProvider, {
    Future<void> Function()? beforeLocalWipe,
  }) async {
    try {
      final credential = await credentialProvider();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !user.isAnonymous) {
        final result = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        await _guardAccountSwitch(result.user!.uid, beforeLocalWipe);
        notifyListeners();
        return result.user!.uid;
      }
      try {
        final result = await user.linkWithCredential(credential);
        await _guardFreshLink(result.user!.uid, beforeLocalWipe);
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
        await _guardAccountSwitch(result.user!.uid, beforeLocalWipe);
        notifyListeners();
        return result.user!.uid;
      }
    } on FirebaseAuthException catch (e) {
      throw AccountException(_reasonFor(e), e);
    }
  }

  /// サインアウトは端末ローカルのSQLiteデータを消さない設計のため、同じ端末で
  /// 別の既存アカウントへ切り替えると、前のアカウントのデータが残ったまま
  /// 新アカウントの「クラウドから復元」で新アカウント側のFirestoreへ誤って
  /// 送信されてしまう恐れがある。ローカルデータの持ち主として記録済みの
  /// uidと、今回サインインしたuidが食い違う場合（＝別の既存アカウントへの
  /// 切り替え）は、ローカルデータを消してから新しい持ち主を記録する
  /// （[[project_voicejournal_knowledge_base_chat]]参照）。
  ///
  /// このメソッドは[signInWithCredential]のうち、匿名ユーザーの
  /// `linkWithCredential`がそのまま成功するケース（uidが変わらない、
  /// 匿名データの初回昇格）では呼ばれない——そちらは[_guardFreshLink]参照。
  /// つまりここに到達するのは「currentUserが既に実アカウント」か、
  /// 「匿名ユーザーのリンクが`credential-already-in-use`で失敗し、既に
  /// 別の場所で使われている既存アカウントへのサインインにフォールバックした」
  /// 場合のいずれかであり、どちらも「このnewUidが今のローカルデータの
  /// 持ち主だとは確認できていない」点は同じ。
  ///
  /// 以前は記録が無い場合（previousOwner == null）を「この端末で初めての
  /// 実アカウント紐付け」とみなして無条件でスキップしていたが、これは
  /// 誤りだった: 匿名のまま日記を書いていた端末で、他の端末で既に使われて
  /// いる別の既存アカウントにサインインした場合（上記のフォールバック
  /// ルート）もprevious Owner==nullになるため、素通りしてしまい、匿名で
  /// 書いた（＝本来その既存アカウントとは無関係な）日記データが
  /// [_afterAuthSuccess]のfullSyncでそのままその既存アカウントの
  /// Firestoreへpushされる、という実在するクロスアカウント漏えい経路が
  /// あった。安全側に倒し、previousOwnerがnewUidと一致することが確認できる
  /// 場合（＝同じアカウントへ再サインインしただけ）以外は常に消す。
  Future<void> _guardAccountSwitch(
    String newUid, [
    Future<void> Function()? beforeLocalWipe,
  ]) async {
    final previousOwner = await _settings.getLocalDataOwnerUid();
    if (previousOwner != newUid) {
      await beforeLocalWipe?.call();
      await DbService.instance.wipeAllLocalData();
    }
    await _settings.setLocalDataOwnerUid(newUid);
  }

  /// [signInWithCredential]の`linkWithCredential`成功パス専用のガード。
  /// linkWithCredentialはuidを変えない（匿名→本アカウントへの昇格）ため、
  /// 一見「ガード不要」に見える——実際、記録が無い場合（previousOwner ==
  /// null、＝この端末で初めての実アカウント紐付け）はローカルの匿名データが
  /// そのままこのuidの所有物になるだけなので消してはならない。
  /// [_guardAccountSwitch]と違いここではnullを「安全」として扱う。
  ///
  /// ただし例外がある: `signOut`はlocalDataOwnerUidを消さずに新しい匿名uid
  /// を再発行するため（[signOut]参照）、「サインアウト→(前アカウントの
  /// データが残ったまま)匿名で使用→新しい/別のアカウントへ紐付け」という
  /// 経路では、previousOwnerに前アカウントの実uidが残ったままこの
  /// linkWithCredentialが（新しいuidで）成功する。この場合はローカル
  /// SQLiteに前アカウントのデータが残っているので、previousOwnerが
  /// 記録されており、かつ今回のuidと食い違う場合は消す。
  Future<void> _guardFreshLink(
    String newUid, [
    Future<void> Function()? beforeLocalWipe,
  ]) async {
    final previousOwner = await _settings.getLocalDataOwnerUid();
    if (previousOwner != null && previousOwner != newUid) {
      await beforeLocalWipe?.call();
      await DbService.instance.wipeAllLocalData();
    }
    await _settings.setLocalDataOwnerUid(newUid);
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
  /// [beforeLocalWipe]は[JournalStore.teardownAllLocalSideEffects]参照
  /// （[signInWithCredential]の同名パラメータと同じ役割）。
  Future<String> deleteAccount({
    Future<void> Function()? beforeLocalWipe,
  }) async {
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
    await beforeLocalWipe?.call();
    await DbService.instance.wipeAllLocalData();
    await _settings.setLocalDataOwnerUid(null);
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
