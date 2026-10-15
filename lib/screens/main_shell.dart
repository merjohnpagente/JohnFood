import 'package:flutter/material.dart';
import '../app_info.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class MainShell extends StatefulWidget {
  final List<Widget> pages;
  final int Function(BuildContext context) cartCount;
  const MainShell({super.key, required this.pages, required this.cartCount})
      : assert(pages.length == 4);
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  static const _labels = ['Home', 'Orders', 'Cart', 'Profile'];
  static const _icons = [
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.shopping_cart_outlined,
    Icons.person_outline_rounded,
  ];
  static const _selectedIcons = [
    Icons.home_rounded,
    Icons.receipt_long_rounded,
    Icons.shopping_cart_rounded,
    Icons.person_rounded,
  ];

  Widget _icon(int i, int count, {required bool selected}) {
    final icon = Icon(selected ? _selectedIcons[i] : _icons[i]);
    if (i != 2) return icon;
    return Badge(isLabelVisible: count > 0, label: Text('$count'), child: icon);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.cartCount(context);
    final body = IndexedStack(index: _index, children: widget.pages);
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= Breakpoints.tablet;
          final extended = c.maxWidth >= Breakpoints.desktop;
          if (!wide) {
            return Scaffold(
              body: SafeArea(bottom: false, child: body),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: [
                  for (var i = 0; i < 4; i++)
                    NavigationDestination(
                      icon: _icon(i, count, selected: false),
                      selectedIcon: _icon(i, count, selected: true),
                      label: _labels[i],
                    ),
                ],
              ),
            );
          }
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    backgroundColor: Colors.white,
                    selectedIndex: _index,
                    extended: extended,
                    minExtendedWidth: 200,
                    indicatorColor: AppColors.tint,
                    selectedIconTheme: const IconThemeData(color: AppColors.primary),
                    unselectedIconTheme: const IconThemeData(color: AppColors.muted),
                    selectedLabelTextStyle: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600),
                    unselectedLabelTextStyle: const TextStyle(color: AppColors.muted),
                    onDestinationSelected: (i) => setState(() => _index = i),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: extended
                          ? const Text(kAppName,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary))
                          : const Icon(Icons.fastfood_rounded, color: AppColors.primary),
                    ),
                    destinations: [
                      for (var i = 0; i < 4; i++)
                        NavigationRailDestination(
                          icon: _icon(i, count, selected: false),
                          selectedIcon: _icon(i, count, selected: true),
                          label: Text(_labels[i]),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: ContentWidth(child: body)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
