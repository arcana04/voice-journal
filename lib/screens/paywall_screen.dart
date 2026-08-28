import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';
import '../state/subscription_store.dart';

/// Proプランへの加入を促す画面。RevenueCatの「現在のOffering」に設定された
/// パッケージ（月額・年額・買い切り）を1枚ずつ選べるカードとして一覧表示し、
/// 選んだプランの購入・復元を行う。
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final PurchaseService _purchases = PurchaseService.instance;
  late final Future<Offering?> _offeringFuture = _purchases.fetchCurrentOffering();
  bool _busy = false;
  Package? _selected;

  Future<void> _purchase() async {
    final package = _selected;
    if (package == null) return;
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
            final plans = _buildPlanSlots(l10n, packages);
            final anyPurchasable = plans.any((p) => p.package != null);

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
                const SizedBox(height: 28),
                if (packages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.paywallUnavailable,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else ...[
                  for (final plan in plans) ...[
                    _PlanCard(
                      plan: plan,
                      selected: _selected == plan.package && plan.package != null,
                      onTap: plan.package == null
                          ? null
                          : () => setState(() => _selected = plan.package),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_busy || !anyPurchasable || _selected == null)
                          ? null
                          : _purchase,
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
                          : Text(l10n.paywallContinueButton),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
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

  /// 表示したい3プラン（月額・年額・買い切り）の枠を作り、Offeringに実在する
  /// パッケージがあれば紐付ける。RevenueCat側にまだ買い切り商品が設定されて
  /// いない場合は[_PlanSlot.package]がnullのまま「近日公開」表示になる。
  List<_PlanSlot> _buildPlanSlots(AppLocalizations l10n, List<Package> packages) {
    Package? find(PackageType type) {
      for (final p in packages) {
        if (p.packageType == type) return p;
      }
      return null;
    }

    final monthly = find(PackageType.monthly);
    final annual = find(PackageType.annual);
    final lifetime = find(PackageType.lifetime);

    final slots = [
      _PlanSlot(label: l10n.paywallPlanMonthly, package: monthly),
      _PlanSlot(
        label: l10n.paywallPlanAnnual,
        package: annual,
        badge: l10n.paywallPlanRecommended,
      ),
      _PlanSlot(
        label: l10n.paywallPlanLifetime,
        package: lifetime,
        caption: l10n.paywallPlanLifetimeCaption,
      ),
    ];

    // 起動時、実在するパッケージの中から一番目立たせたいもの（年額があれば
    // それ、無ければ最初に見つかったもの）を初期選択にする。
    if (_selected == null) {
      final initial = annual ?? monthly ?? lifetime;
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selected = initial);
        });
      }
    }

    return slots;
  }
}

class _PlanSlot {
  final String label;
  final Package? package;
  final String? badge;
  final String? caption;

  const _PlanSlot({required this.label, required this.package, this.badge, this.caption});
}

class _PlanCard extends StatelessWidget {
  final _PlanSlot plan;
  final bool selected;
  final VoidCallback? onTap;

  const _PlanCard({required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final available = plan.package != null;
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: available ? 1 : 0.5,
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (plan.badge != null) ...[
                            const SizedBox(width: 8),
                            _Badge(text: plan.badge!),
                          ],
                        ],
                      ),
                      if (plan.caption != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            plan.caption!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                available
                    ? Text(
                        plan.package!.storeProduct.priceString,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Text(
                        l10n.paywallPlanComingSoon,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
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
