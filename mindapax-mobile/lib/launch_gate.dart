import 'package:flutter/material.dart';

import 'intro/intro_carousel_page.dart';
import 'intro/intro_prefs.dart';
import 'root_gate.dart';
import 'splash.dart';

class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  bool _deciding = true;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final seen = await IntroPrefs.isCompleted();
    if (!mounted) return;
    setState(() {
      _deciding = false;
      _showIntro = !seen;
    });
  }

  Future<void> _completeIntro() async {
    await IntroPrefs.setCompleted(true);
    if (!mounted) return;
    setState(() => _showIntro = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_deciding) return const BrandedSplash();
    if (_showIntro) {
      return IntroCarouselPage(onFinished: _completeIntro);
    }
    return const RootGate();
  }
}
