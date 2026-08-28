import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../screens/paywall_screen.dart';
import '../services/custom_background_service.dart';
import '../state/subscription_store.dart';

/// お気に入り設定・日記編集どちらの背景選択シートからも呼ばれる、
/// 「自分の画像を追加」タップ時の共通処理（Pro限定機能）。
/// Proでなければ[sheetContext]のシートを閉じてペイウォールへ遷移する。
/// Proなら画像を1枚選ばせてアプリ内にコピーし、[onPicked]に新しい
/// backgroundIdを渡した上でシートを閉じる。
Future<void> pickCustomBackground(
  BuildContext sheetContext, {
  required ValueChanged<String> onPicked,
}) async {
  final isPro = sheetContext.read<SubscriptionStore>().isPro;
  if (!isPro) {
    Navigator.of(sheetContext).pop();
    Navigator.of(
      sheetContext,
    ).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
    return;
  }

  final picker = ImagePicker();
  XFile? picked;
  try {
    picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  } catch (e) {
    if (!sheetContext.mounted) return;
    ScaffoldMessenger.of(sheetContext).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(sheetContext)!.mediaPickFailed('$e')),
      ),
    );
    return;
  }
  if (picked == null) return;

  final backgroundId = await CustomBackgroundService().saveCustomBackground(
    File(picked.path),
  );
  onPicked(backgroundId);
  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
}
