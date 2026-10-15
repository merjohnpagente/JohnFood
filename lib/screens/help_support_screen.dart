import 'package:flutter/material.dart';
import '../app_info.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/responsive.dart';
import '../widgets/ui_kit.dart';

/// Help & Support: FAQs, contact channels and app info.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      'How do I track my order?',
      'Open Orders, tap your active order, and follow the rider on the live map with ETA.'
    ),
    (
      'What payment methods are accepted?',
      'Cash on delivery, GCash and Maya. Pick your preferred method under Profile > Payment Methods.'
    ),
    (
      'Do my cart and addresses survive refresh?',
      'Yes. Your cart is saved on this device and your addresses live in your account in the database.'
    ),
    (
      'How do I cancel an order?',
      'You can cancel while it is still Pending from the Orders tab or the tracking screen.'
    ),
    (
      'I forgot my password. What now?',
      'Tap Forgot password on the login screen and follow the reset link sent to your email.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            Entrance(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Need a hand?',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text(
                                'Message us anytime — replies within a day.',
                                style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _faqs.length; i++)
              Entrance(
                delay:
                    Duration(milliseconds: ((i + 1) * 50).clamp(0, 250)),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    shape: const Border(),
                    title: Text(_faqs[i].$1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 16),
                        child: Text(_faqs[i].$2,
                            style: const TextStyle(
                                color: AppColors.inkSecondary,
                                height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ),
            Entrance(
              delay: const Duration(milliseconds: 300),
              child: Card(
                child: Column(
                  children: const [
                    MenuTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'support@johnfoods.app',
                      onTap: null,
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16),
                    MenuTile(
                      icon: Icons.phone_outlined,
                      title: '+63 (912) 345-6789',
                      onTap: null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('$kAppName v1.0.0 • $kDeveloperCredit',
                  style:
                      TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
