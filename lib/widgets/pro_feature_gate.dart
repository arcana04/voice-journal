import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/paywall_screen.dart';
import 'app_background_image.dart';
import 'scrim_text.dart';

/// Pro限定機能の入り口で、非Pro時に本体の代わりに表示する案内。
/// タップでペイウォールへ誘導する。
class ProFeatureGate extends StatelessWidget {
  final String title;
  final String description;

  const ProFeatureGate({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        const Positioned.fill(child: AppBackgroundImage()),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ScrimText(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      ),
                      child: Text(l10n.planUpgrade),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
