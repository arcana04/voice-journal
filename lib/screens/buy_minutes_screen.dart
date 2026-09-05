import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';

/// Pro/買い切みプランの月間録音時間の上限に達したユーザー向けの、消費型IAP
/// 「追加60分パック」購入画面。PaywallScreenはサブスク/買い切りの3枠固定
/// レイアウトで消費型商品を扱えないため、専用の小さな画面として分ける。
class BuyMinutesScreen extends StatefulWidget {
  const BuyMinutesScreen({super.key});

  @override
  State<BuyMinutesScreen> createState() => _BuyMinutesScreenState();
}

class _BuyMinutesScreenState extends State<BuyMinutesScreen> {
  final PurchaseService _purchases = PurchaseService.instance;
  late final Future<Package?> _packageFuture = _purchases.findPackageByProductId(
    RevenueCatConfig.extraMinutesPackProductId,
  );
  bool _busy = false;

  Future<void> _purchase(Package package) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final purchased = await _purchases.purchaseConsumable(package);
      if (!mounted) return;
      if (purchased) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.buyMinutesPurchaseSuccess)));
        Navigator.of(context).pop();
      }
      // purchased == false はユーザー自身によるキャンセルなので何もしない。
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.buyMinutesPurchaseFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.buyMinutesTitle)),
      body: SafeArea(
        child: FutureBuilder<Package?>(
          future: _packageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final package = snapshot.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.buyMinutesDescription,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                if (package == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.buyMinutesUnavailable,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : () => _purchase(package),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.buyMinutesPurchaseButton(
                                package.storeProduct.priceString,
                              ),
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
