import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/env_config.dart';
import 'config/theme.dart';
import 'providers/settings_provider.dart';
import 'providers/audio_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/slideshow_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Daily Awe',
        theme: AppTheme.darkTheme,
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  bool _showOnboarding = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('AppNavigator: Initializing');
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    debugPrint('AppNavigator: Checking onboarding status');
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;
      debugPrint('AppNavigator: Onboarding completed: $hasCompletedOnboarding');
      
      if (mounted) {
        setState(() {
          _showOnboarding = !hasCompletedOnboarding;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AppNavigator: Error checking onboarding status: $e');
      if (mounted) {
        setState(() {
          _showOnboarding = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    debugPrint('AppNavigator: Completing onboarding request received');
    
    try {
      debugPrint('AppNavigator: Starting navigation process');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      
      if (!context.mounted) return;
      
      debugPrint('AppNavigator: Navigating to slideshow');
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SlideshowScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('AppNavigator: Error completing onboarding: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving preferences. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onComplete: () {
        debugPrint('AppNavigator: Splash screen complete');
        if (_isLoading) {
          debugPrint('AppNavigator: Still loading, waiting...');
          return;
        }
        
        if (!mounted) {
          debugPrint('AppNavigator: Widget not mounted, ignoring splash completion');
          return;
        }
        
        if (_showOnboarding) {
          debugPrint('AppNavigator: Showing onboarding screen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(
                onComplete: () => _completeOnboarding(context),
              ),
            ),
          );
        } else {
          debugPrint('AppNavigator: Showing slideshow screen directly');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SlideshowScreen()),
          );
        }
      },
    );
  }
}
