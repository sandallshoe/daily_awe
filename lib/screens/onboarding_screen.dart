import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'dart:async';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;
  Timer? _debounceTimer;
  bool _isCompleting = false;

  Future<void> _handleComplete() async {
    debugPrint('OnboardingScreen: Handling completion request');
    if (_isCompleting) {
      debugPrint('OnboardingScreen: Already completing, ignoring request');
      return;
    }

    if (!mounted) {
      debugPrint('OnboardingScreen: Widget not mounted, ignoring request');
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      debugPrint('OnboardingScreen: Starting completion process');
      // Minimum visual feedback
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      debugPrint('OnboardingScreen: Calling onComplete callback');
      await widget.onComplete();
    } catch (e) {
      debugPrint('OnboardingScreen: Error during completion: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error proceeding to next screen. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint('OnboardingScreen: Back button pressed');
        return !_isCompleting;
      },
      child: Stack(
        children: [
          IntroductionScreen(
            pages: [
              PageViewModel(
                title: 'Welcome to Daily Awe',
                body: 'Research shows experiencing awe daily can improve your mood and reduce stress. This app delivers a moment of wonder — no scrolling, no doom. Just awe.',
                image: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.landscape,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                decoration: PageDecoration(
                  titleTextStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  bodyTextStyle: const TextStyle(fontSize: 18),
                  pageColor: Theme.of(context).colorScheme.background,
                ),
              ),
            ],
            showSkipButton: true,
            skip: const Text('Skip'),
            next: const Text('Next'),
            done: _isCompleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Get Started'),
            onDone: _handleComplete,
            onSkip: _handleComplete,
            skipOrBackFlex: 0,
            nextFlex: 0,
            globalBackgroundColor: Theme.of(context).colorScheme.background,
            dotsDecorator: DotsDecorator(
              size: const Size(10, 10),
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
              activeSize: const Size(22, 10),
              activeColor: Theme.of(context).colorScheme.primary,
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            controlsPadding: const EdgeInsets.all(16),
            curve: Curves.fastLinearToSlowEaseIn,
            isProgressTap: !_isCompleting,
            isProgress: true,
            freeze: _isCompleting,
            animationDuration: 400,
          ),
          if (_isCompleting)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
} 