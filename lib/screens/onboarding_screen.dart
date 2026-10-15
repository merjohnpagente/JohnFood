import 'package:flutter/material.dart';
import '../app_info.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'auth_gate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;
  static const _items = [
    ('Browse cravings', 'Fresh menu across 8 categories, ready to search.', Icons.fastfood_rounded),
    ('Track live', 'Follow your rider on the map with live ETA.', Icons.map_rounded),
    ('Pay your way', 'Cash on delivery or e-wallet, zero hassle.', Icons.payments_rounded),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 640,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _done,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _i = i),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.tint,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(_items[i].$3, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        Text(_items[i].$1,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(_items[i].$2, textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _i == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _i == i ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(
                  onPressed: _i == _items.length - 1
                      ? _done
                      : () => _page.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic),
                  child: Text(_i == _items.length - 1 ? 'Get started' : 'Next'),
                ),
              ),
              const Text(kDeveloperCredit, style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _done() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const AuthGate()));
}
