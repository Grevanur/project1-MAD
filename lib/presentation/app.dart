import 'package:flutter/material.dart';

class AdaptiveFocusApp extends StatelessWidget {
  const AdaptiveFocusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Adaptive Focus Studio',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF315C4B),
      useMaterial3: true,
    ),
    home: const FoundationScreen(),
  );
}

class FoundationScreen extends StatelessWidget {
  const FoundationScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Adaptive Focus Studio')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'The tested data, state, timer, and Session Scout foundation is ready.',
            ),
            SizedBox(height: 8),
            Text('Presentation screens are assigned in TEAMMATE_HANDOFF.md.'),
          ],
        ),
      ),
    ),
  );
}
