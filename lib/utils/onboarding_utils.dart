import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_accessories/providers/onboarding_status_provider.dart';

class OnboardingUtils {
  /// Reset onboarding state for testing purposes
  static Future<void> resetOnboarding(WidgetRef ref) async {
    await ref.read(onboardingActionsProvider).resetOnboarding();
  }

  /// Check if user has seen onboarding (async)
  static Future<bool> hasSeenOnboarding(WidgetRef ref) async {
    final asyncValue = ref.read(onboardingStatusProvider);
    return asyncValue.when(
      data: (value) => value,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  /// Mark onboarding as complete
  static Future<void> markOnboardingComplete(WidgetRef ref) async {
    await ref.read(onboardingActionsProvider).markOnboardingComplete();
  }
}
