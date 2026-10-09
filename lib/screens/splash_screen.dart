import 'package:flutter/material.dart';
import '../app_info.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final Duration holdFor;
  const SplashScreen({super.key, required this.onFinished, this.holdFor = const Duration(milliseconds: 2000)});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _creditFade;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _iconFade = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.40, curve: Curves.easeOut));
    _iconScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack)));
    _nameFade = CurvedAnimation(parent: _c, curve: const Interval(0.25, 0.65, curve: Curves.easeOut));
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _c, curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic)));
    _creditFade = CurvedAnimation(parent: _c, curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
    Future.delayed(widget.holdFor, () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _iconFade,
                        child: ScaleTransition(
                          scale: _iconScale,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(Icons.fastfood_rounded, size: 48, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _nameFade,
                        child: SlideTransition(
                          position: _nameSlide,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                kAppName,
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Good Food, Good Mood',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: _creditFade,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  kDeveloperCredit,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
