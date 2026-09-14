import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'account_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const _kHeroBg = Color(0xFF0A0818);
const _kAuroraBlue = Color(0xFF4B6FF2);
const _kAuroraPurple = Color(0xFF8B5CF6);
const _kAuroraPink = Color(0xFFD46BD1);

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _aiConsentChecked = false;

  static const _pageCount = 5;
  // マイク許可+OpenAIへのデータ送信の開示・同意ページ(App Store審査
  // ガイドライン5.1.1(i)/5.1.2(i)対応)。このページ以降はスキップ不可、
  // 同意チェックが入るまで先へ進めない。
  static const _aiConsentPageIndex = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _aiConsentPageIndex && !_aiConsentChecked) {
      return;
    }
    if (_page == _pageCount - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _page == _pageCount - 1;

    return Scaffold(
      backgroundColor: _kHeroBg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Visibility(
                  visible: !isLastPage && _page < _aiConsentPageIndex,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: TextButton(
                    onPressed: widget.onFinished,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.85),
                    ),
                    child: Text(l10n.onboardingSkip),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _HeroOnboardingPage(
                    title: l10n.onboardingPage1Title,
                    body: l10n.onboardingPage1Body,
                  ),
                  _OnboardingPage(
                    icon: Icons.auto_awesome,
                    title: l10n.onboardingPage2Title,
                    body: l10n.onboardingPage2Body,
                    trailing: const _SortPreviewIcons(),
                  ),
                  _OnboardingPage(
                    icon: Icons.card_giftcard_rounded,
                    title: l10n.onboardingFreeTierTitle,
                    body: l10n.onboardingFreeTierBody,
                  ),
                  _OnboardingPage(
                    icon: Icons.mic_none_rounded,
                    title: l10n.onboardingMicTitle,
                    body: l10n.onboardingMicBody,
                    trailing: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CheckboxListTile(
                        value: _aiConsentChecked,
                        onChanged: (value) =>
                            setState(() => _aiConsentChecked = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        checkColor: _kHeroBg,
                        activeColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        title: Text(
                          l10n.onboardingAiConsentLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _OnboardingPage(
                    icon: Icons.waving_hand,
                    title: l10n.onboardingPage3Title,
                    body: l10n.onboardingPage3Body,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pageCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _page ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _page
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  _HeroNextButton(
                    label: isLastPage
                        ? l10n.onboardingGetStarted
                        : l10n.onboardingNext,
                    onTap:
                        (_page == _aiConsentPageIndex && !_aiConsentChecked)
                            ? null
                            : _next,
                  ),
                  if (isLastPage) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AccountScreen()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.85),
                      ),
                      child: Text(l10n.onboardingCreateAccount),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // 本文が長いページ(プライバシー説明・無料枠説明など)が小さい画面で
    // オーバーフローしないよう、はみ出す場合だけスクロール可能にする
    // （収まる画面では従来通り中央寄せに見える）。1枚目([_HeroOnboardingPage])
    // と統一感を出すため、背景・アイコン・文字色もオーロラ配色に揃えている。
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _AuroraPainter())),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_kAuroraBlue, _kAuroraPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kAuroraPurple.withValues(alpha: 0.55),
                            blurRadius: 50,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 32),
                      trailing!,
                    ],
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

/// 最初のオンボーディングページだけに使う、オーロラ風グラデーションの
/// フルスクリーン演出。ブランドの第一印象を強めるための特別扱いで、
/// 他のページは通常の[_OnboardingPage]のまま。
class _HeroOnboardingPage extends StatelessWidget {
  final String title;
  final String body;

  const _HeroOnboardingPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _AuroraPainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: _kAuroraBlue,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Voice Brain',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'SPEAK TODAY,',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  letterSpacing: 2,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_kAuroraBlue, _kAuroraPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kAuroraPurple.withValues(alpha: 0.55),
                          blurRadius: 60,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.center,
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

/// [_HeroOnboardingPage]の背景に敷く、柔らかいオーロラ風の帯と星の点描。
/// 静的な演出のため[shouldRepaint]は常にfalse。
class _AuroraPainter extends CustomPainter {
  const _AuroraPainter();

  void _drawRibbon(
    Canvas canvas,
    Size size,
    List<Color> colors,
    double yFactor,
    double amplitude,
    double thickness,
  ) {
    final w = size.width;
    final baseY = size.height * yFactor;
    final path = Path()
      ..moveTo(-w * 0.2, baseY)
      ..quadraticBezierTo(w * 0.25, baseY - amplitude, w * 0.5, baseY)
      ..quadraticBezierTo(
        w * 0.75,
        baseY + amplitude,
        w * 1.2,
        baseY - amplitude * 0.4,
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, w, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kHeroBg);
    _drawRibbon(
      canvas,
      size,
      [_kAuroraBlue.withValues(alpha: 0.55), _kAuroraPurple.withValues(alpha: 0)],
      0.30,
      90,
      160,
    );
    _drawRibbon(
      canvas,
      size,
      [_kAuroraPurple.withValues(alpha: 0.5), _kAuroraPink.withValues(alpha: 0)],
      0.55,
      70,
      140,
    );
    _drawRibbon(
      canvas,
      size,
      [_kAuroraPink.withValues(alpha: 0.35), _kAuroraBlue.withValues(alpha: 0)],
      0.78,
      60,
      120,
    );

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    const stars = [
      Offset(0.12, 0.20),
      Offset(0.75, 0.16),
      Offset(0.28, 0.62),
      Offset(0.86, 0.52),
      Offset(0.62, 0.08),
      Offset(0.18, 0.72),
    ];
    for (final s in stars) {
      canvas.drawCircle(Offset(s.dx * size.width, s.dy * size.height), 2, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => false;
}

/// [_HeroOnboardingPage]専用のグラデーション角丸ボタン。設定画面の
/// [_UpgradeButton]と似た見た目だが、色味をオーロラ配色に合わせている。
class _HeroNextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _HeroNextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return SizedBox(
      width: double.infinity,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kAuroraBlue, _kAuroraPurple, _kAuroraPink],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortPreviewIcons extends StatelessWidget {
  const _SortPreviewIcons();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (Icons.menu_book, l10n.navDiary),
      (Icons.lightbulb, l10n.navIdea),
      (Icons.checklist, l10n.navTask),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (icon, label) in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
