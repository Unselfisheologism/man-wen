import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dart_crash_reporter.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _OnboardPage(
                    icon: Icons.shield,
                    title: 'Realtime Protection',
                    body: 'Blocks thousands of adult and NSFW websites at the network level — no visual detection needed.',
                  ),
                  _OnboardPage(
                    icon: Icons.timeline,
                    title: 'Rebuild Your Streak',
                    body: 'Track progress, increase resilience with urge-surfing tools, accountability reminders and daily checkins.',
                  ),
                  _OnboardPage(
                    icon: Icons.lock,
                    title: 'Private by Default',
                    body: 'All data stays on device. Encrypted local storage, biometric lock, no analytics, no tracking.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.all(6), width: _page == i ? 22 : 10, height: 10, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8)))),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onPrimaryButtonPressed,
                  child: Text(_page == 2 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPrimaryButtonPressed() {
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
    } catch (e, s) {
      // Persisting the flag isn't critical — even if it fails, we can still
      // navigate to the home screen this session. Report but don't block.
      DartCrashReporter.report('Failed to save onboarding_complete', e, s);
    }
    if (!mounted) return;
    // Use a MaterialPageRoute, not pushReplacementNamed('/home') — the
    // MaterialApp has no `routes:` table, so a named-route push would
    // throw "Could not find a generator for route /home".
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardPage({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 48),
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(body, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
