import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

class SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;
  const SearchField({super.key, required this.onChanged, this.hint = 'Search food'});
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
      ),
    );
  }
}

class CategoryBar extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  const CategoryBar({super.key, required this.labels, required this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = i == selected;
          return AnimatedScale(
            scale: on ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ChoiceChip(
              label: Text(labels[i]),
              selected: on,
              showCheckmark: false,
              onSelected: (_) => onSelected(i),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : AppColors.ink,
              ),
            ),
          );
        },
      ),
    );
  }
}

class FoodImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  const FoodImage(this.path, {super.key, this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.tint,
          child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 40),
        ),
      );
    }
    if (path.startsWith('foodImages/') || path.length > 500) {
      try {
        final b64 = path.startsWith('foodImages/') ? null : path;
        if (b64 != null) {
          return Image.memory(base64Decode(b64), fit: fit,
              errorBuilder: (_, __, ___) => _fallback());
        }
      } catch (_) {}
      return _fallback();
    }
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.tint,
        child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 40),
      );
}

class FoodCard extends StatelessWidget {
  final String name;
  final String price;
  final double rating;
  final String deliveryTime;
  final Widget image;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const FoodCard({
    super.key,
    required this.name,
    required this.price,
    required this.rating,
    required this.deliveryTime,
    required this.image,
    required this.onTap,
    required this.onAdd,
  });
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.1)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(tag: 'food-$name', child: image),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                            const SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(deliveryTime,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(price,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.3)),
                        const Spacer(),
                        Material(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: onAdd,
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  final String label;
  final String? total;
  final VoidCallback? onPressed;
  const BottomActionBar({super.key, required this.label, this.total, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFE8E3))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Row(
              children: [
                if (total != null) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      Text(total!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(child: FilledButton(onPressed: onPressed, child: Text(label))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  const QuantityStepper({super.key, required this.qty, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: () => onChanged(qty - 1),
          icon: const Icon(Icons.remove_rounded),
          tooltip: 'Decrease',
        ),
        SizedBox(
          width: 36,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, a) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
                  child: FadeTransition(opacity: a, child: c)),
              child: Text('$qty', key: ValueKey(qty), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => onChanged(qty + 1),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Increase',
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final label = {
      'pending': 'Pending',
      'preparing': 'Preparing',
      'on_the_way': 'On the way',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    }[status] ?? status;
    final color = {
      'pending': AppColors.warning,
      'preparing': AppColors.primary,
      'on_the_way': const Color(0xFF1565C0),
      'delivered': AppColors.success,
      'cancelled': AppColors.error,
    }[status] ?? AppColors.muted;
    final bg = {
      'pending': AppColors.warningBg,
      'preparing': AppColors.tint,
      'on_the_way': const Color(0xFFE3F2FD),
      'delivered': AppColors.successBg,
      'cancelled': AppColors.errorBg,
    }[status] ?? const Color(0xFFF5F5F5);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.tint,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted)),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 44, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220, mainAxisExtent: 280, mainAxisSpacing: 14, crossAxisSpacing: 14),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false});
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const SecondaryButton({super.key, required this.label, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscure;
  final Widget? suffix;
  final Widget? prefix;
  final String? hint;
  final int maxLines;
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscure = false,
    this.suffix,
    this.prefix,
    this.hint,
    this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscure,
      maxLines: maxLines,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: hint == null ? label : null,
        hintText: hint ?? label,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warningBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(child: Text('Offline. Showing saved data.', style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
/// Profile / settings menu row with icon bubble and chevron.
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? iconBg;
  final Color? titleColor;
  final VoidCallback? onTap;
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.iconBg,
    this.titleColor,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg ?? AppColors.tint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            size: 20, color: iconColor ?? AppColors.primary),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: titleColor ?? AppColors.ink)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.muted),
      onTap: onTap,
    );
  }
}

/// Shimmer skeleton block for loading states.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  const ShimmerBox({super.key, this.width, this.height, this.radius = 12});
  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.shimmer,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// "or" divider used on auth screens.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}

/// Brand logo box used on splash / login / register.
class BrandLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  const BrandLogo({super.key, this.size = 72, this.iconSize = 38});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(Icons.fastfood_rounded, size: iconSize, color: Colors.white),
    );
  }
}

/// Auto-scrolling promo banner carousel (dark card like the design mockup).
class PromoCarousel extends StatefulWidget {
  final List<PromoSlide> slides;
  final ValueChanged<int> onOrder;
  const PromoCarousel({super.key, required this.slides, required this.onOrder});
  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class PromoSlide {
  final String title;
  final String subtitle;
  final String image;
  const PromoSlide({required this.title, required this.subtitle, required this.image});
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _page = PageController(viewportFraction: 0.94);
  int _i = 0;

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1) _auto();
  }

  Future<void> _auto() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted || widget.slides.length < 2) return;
      final next = (_i + 1) % widget.slides.length;
      if (_page.hasClients) {
        await _page.animateToPage(next,
            duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
      } else {
        return;
      }
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _page,
            onPageChanged: (i) => setState(() => _i = i),
            itemCount: widget.slides.length,
            itemBuilder: (_, i) {
              final s = widget.slides[i];
              return AnimatedScale(
                scale: i == _i ? 1.0 : 0.96,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1B14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        right: -20,
                        top: -10,
                        bottom: -10,
                        width: 190,
                        child: FoodImage(s.image),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2A1B14),
                              const Color(0xFF2A1B14).withOpacity(0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(s.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2)),
                            const SizedBox(height: 4),
                            Text(s.subtitle,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7), fontSize: 11)),
                            const SizedBox(height: 10),
                            Material(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => widget.onOrder(i),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Order Now',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _i ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Food list row (All Foods screen) with image, price, rating and add button.
class FoodRow extends StatelessWidget {
  final String name;
  final String price;
  final double rating;
  final String deliveryTime;
  final Widget image;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const FoodRow({
    super.key,
    required this.name,
    required this.price,
    required this.rating,
    required this.deliveryTime,
    required this.image,
    required this.onTap,
    required this.onAdd,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 76, height: 76, child: image),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(price,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFFFB300)),
                        Text(' ${rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.muted),
                        Text(' $deliveryTime',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onAdd,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round orange "+" add button with press bounce.
class AddButton extends StatefulWidget {
  final VoidCallback onAdd;
  final double size;
  const AddButton({super.key, required this.onAdd, this.size = 40});
  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.fast);
    _scale = Tween<double>(begin: 1, end: 0.8).animate(
        CurvedAnimation(parent: _c, curve: AppMotion.ease));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.4),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            await _c.forward();
            await _c.reverse();
            widget.onAdd();
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(Icons.add_rounded,
                color: Colors.white, size: widget.size * 0.55),
          ),
        ),
      ),
    );
  }
}

