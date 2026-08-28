import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';
import '../state/subscription_store.dart';

/// Proプランへの加入を促す画面。RevenueCatの「現在のOffering」に設定された
/// パッケージ（月額・年額など）を一覧表示し、購入・復元を行う。
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final PurchaseService _purchases = PurchaseService.instance;
  late final Future<Offering?> _offeringFuture = _purchases.fetchCurrentOffering();
  bool _busy = false;

  Future<void> _purchase(Package package) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final granted = await _purchases.purchasePackage(package);
      if (!mounted) return;
      if (granted == true) {
        await context.read<SubscriptionStore>().refresh();
        if (!mounted) return;
        Navigator.of(context).pop();
      } else if (granted == false) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.paywallPurchaseFailed)));
      }
      // grantedがnull = ユーザーが購入をキャンセルした場合は何もしない。
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.paywallPurchaseFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final restored = await context.read<SubscriptionStore>().restore();
      if (!mounted) return;
      if (restored) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.paywallRestoreNotFound)));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.paywallPurchaseFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paywallTitle)),
      body: SafeArea(
        child: FutureBuilder<Offering?>(
          future: _offeringFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final packages = snapshot.data?.availablePackages ?? const <Package>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text(l10n.paywallHeadline, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),
                _BenefitRow(
                  icon: Icons.mic_outlined,
                  text: l10n.paywallBenefitDuration,
                ),
                _BenefitRow(icon: Icons.repeat, text: l10n.paywallBenefitCount),
                _BenefitRow(
                  icon: Icons.auto_stories_outlined,
                  text: l10n.paywallBenefitDiaryStyle,
                ),
                _BenefitRow(
                  icon: Icons.image_outlined,
                  text: l10n.paywallBenefitCustomBackground,
                ),
                _BenefitRow(
                  icon: Icons.cloud_upload_outlined,
                  text: l10n.paywallBenefitMediaSync,
                ),
                _BenefitRow(
                  icon: Icons.psychology_outlined,
                  text: l10n.paywallBenefitKnowledgeBase,
                ),
                _BenefitRow(
                  icon: Icons.insights_outlined,
                  text: l10n.paywallBenefitWeeklyReport,
                ),
                const SizedBox(height: 24),
                if (packages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.paywallUnavailable,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  for (final package in packages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _purchase(package),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              package.storeProduct.title,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              package.storeProduct.priceString,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _restore,
                    child: Text(l10n.paywallRestore),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      TextButton(
                        onPressed: () => _openUrl(LegalLinks.termsOfServiceUrl),
                        child: Text(l10n.paywallTerms),
                      ),
                      TextButton(
                        onPressed: () => _openUrl(LegalLinks.privacyPolicyUrl),
                        child: Text(l10n.paywallPrivacy),
                      ),
                    ],
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

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
