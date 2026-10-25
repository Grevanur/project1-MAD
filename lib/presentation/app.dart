import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/activity_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'state/ui_providers.dart';

class AdaptiveFocusApp extends StatelessWidget {
  const AdaptiveFocusApp({super.key, this.activityTick});

  /// Overrides the Activity timer interval. Only tests set this.
  final Duration? activityTick;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF315C4B);
    return MaterialApp(
      title: 'Adaptive Focus Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomeShell(activityTick: activityTick),
    );
  }
}

/// Bottom navigation in portrait, a navigation rail on wide or landscape
/// screens. The page stack keeps its key so a rotation never resets a
/// running session.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, this.activityTick});

  final Duration? activityTick;

  static const _destinations = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    (Icons.timer_outlined, Icons.timer, 'Focus'),
    (Icons.history_outlined, Icons.history, 'History'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    void select(int value) => ref.read(homeTabProvider.notifier).select(value);
    final wide = MediaQuery.sizeOf(context).width >= 720;

    final pages = Expanded(
      key: const ValueKey('pages'),
      child: IndexedStack(
        index: index,
        children: [
          const DashboardScreen(),
          activityTick == null
              ? const ActivityScreen()
              : ActivityScreen(tick: activityTick!),
          const HistoryScreen(),
          const SettingsScreen(),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final (icon, selectedIcon, label) in _destinations)
                    NavigationRailDestination(
                      icon: Icon(icon),
                      selectedIcon: Icon(selectedIcon),
                      label: Text(label),
                    ),
                ],
              ),
            if (wide) const VerticalDivider(width: 1),
            pages,
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: select,
              destinations: [
                for (final (icon, selectedIcon, label) in _destinations)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selectedIcon),
                    label: label,
                  ),
              ],
            ),
    );
  }
}
