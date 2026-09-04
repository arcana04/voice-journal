import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_links.dart';
import '../config/theme_colors.dart';
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
                _PaywallSectionHeader(
                  title: l10n.paywallSectionTitle,
                  subtitle: l10n.paywallSectionSubtitle,
                ),
                const SizedBox(height: 20),
                _BenefitCard(
                  index: 1,
                  icon: Icons.mic_rounded,
                  color: _BenefitColors.indigo,
                  title: Text(l10n.paywallBenefitDurationTitle),
                  valueBefore: l10n.paywallBenefitDurationBefore,
                  valueAfter: l10n.paywallBenefitDurationAfter,
                  description: l10n.paywallBenefitDurationDesc,
                ),
                _BenefitCard(
                  index: 2,
                  icon: Icons.all_inclusive_rounded,
                  color: _BenefitColors.rose,
                  title: Text(l10n.paywallBenefitCountTitle),
                  valueBefore: l10n.paywallBenefitCountBefore,
                  valueAfter: l10n.paywallBenefitCountAfter,
                  description: l10n.paywallBenefitCountDesc,
                ),
                _BenefitCard(
                  index: 3,
                  icon: Icons.image_rounded,
                  color: _BenefitColors.green,
                  title: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: l10n.paywallBenefitCustomBackgroundTitle),
                        TextSpan(
                          text: l10n.paywallBenefitCustomBackgroundHighlight,
                          style: TextStyle(
                            color: _BenefitColors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  description: l10n.paywallBenefitCustomBackgroundDesc,
                ),
                _BenefitCard(
                  index: 4,
                  icon: Icons.crop_free_rounded,
                  color: _BenefitColors.teal,
                  title: Text(l10n.paywallBenefitImageLayoutTitle),
                  description: l10n.paywallBenefitImageLayoutDesc,
                ),
                _BenefitCard(
                  index: 5,
                  icon: Icons.chat_bubble_rounded,
                  color: _BenefitColors.indigo,
                  title: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.paywallBenefitKnowledgeBaseHighlight,
                          style: TextStyle(
                            color: _BenefitColors.indigo,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(text: l10n.paywallBenefitKnowledgeBaseSuffix),
                      ],
                    ),
                  ),
                  description: l10n.paywallBenefitKnowledgeBaseDesc,
                ),
                _BenefitCard(
                  index: 6,
                  icon: Icons.bar_chart_rounded,
                  color: _BenefitColors.amber,
                  title: Text(
                    l10n.paywallBenefitWeeklyReportTitle,
                    style: TextStyle(
                      color: _BenefitColors.amber,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  description: l10n.paywallBenefitWeeklyReportDesc,
                ),
                _BenefitCard(
                  index: 7,
                  icon: Icons.cloud_upload_rounded,
                  color: _BenefitColors.blue,
                  title: Text(
                    l10n.paywallBenefitMediaSyncTitle,
                    style: TextStyle(
                      color: _BenefitColors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  description: l10n.paywallBenefitMediaSyncDesc,
                  badge: l10n.paywallBenefitMediaSyncBadge,
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

/// [_BenefitCard]の各行で使うアクセントカラー。indigoはアプリ全体のブランド
/// カラー（[kAppAccentColor]）そのもので、他の色は機能ごとに見分けやすくする
/// ための固定パレット。
class _BenefitColors {
  static const indigo = kAppAccentColor;
  static const rose = Color(0xFFE84393);
  static const green = Color(0xFF13A67D);
  static const amber = Color(0xFFE2952F);
  static const blue = Color(0xFF3B82F6);
  static const teal = Color(0xFF0D9488);
}

class _PaywallSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PaywallSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👑', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _BenefitColors.indigo.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            subtitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _BenefitColors.indigo,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Proプランの機能一覧を「番号バッジ＋アイコン＋タイトル＋Before→After（任意）＋
/// 説明文」のカードとして見せる。番号バッジはアイコンの左上に重ねて配置する。
class _BenefitCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final Color color;
  final Widget title;
  final String? valueBefore;
  final String? valueAfter;
  final String description;
  final String? badge;

  const _BenefitCard({
    required this.index,
    required this.icon,
    required this.color,
    required this.title,
    this.valueBefore,
    this.valueAfter,
    required this.description,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberLabel = index.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                Positioned(
                  top: -8,
                  left: -8,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      numberLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle.merge(
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                  child: title,
                ),
                if (valueBefore != null && valueAfter != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        valueBefore!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      Text(
                        valueAfter!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    height: 1.35,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}
