import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_status_provider.dart';

/// Widget that checks onboarding status and navigates accordingly
/// This ensures proper async handling of SharedPreferences loading
class OnboardingChecker extends ConsumerWidget {
  const OnboardingChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingStatusAsync = ref.watch(onboardingStatusProvider);

    return onboardingStatusAsync.when(
      data: (hasSeenOnboarding) {
        // Data is loaded, navigate immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasSeenOnboarding) {
            context.go('/login');
          } else {
            context.go('/onboarding');
          }
        });

        // Show loading while navigation happens
        return _buildLoadingScreen(context);
      },
      loading: () => _buildLoadingScreen(context),
      error: (error, stackTrace) {
        // On error, assume first-time user and go to onboarding
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/onboarding');
        });

        return _buildLoadingScreen(context);
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
