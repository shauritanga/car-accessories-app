import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_status_provider.dart';

/// Debug widget to reset onboarding status for testing
/// Only visible in debug mode
class DebugOnboardingReset extends ConsumerWidget {
  const DebugOnboardingReset({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in debug mode
    bool isDebugMode = false;
    assert(isDebugMode = true);
    
    if (!isDebugMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
      right: 16,
      child: FloatingActionButton.small(
        onPressed: () async {
          await ref.read(onboardingActionsProvider).resetOnboarding();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Onboarding reset! Restart app to see onboarding again.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
