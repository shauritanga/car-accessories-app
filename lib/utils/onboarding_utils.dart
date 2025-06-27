import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_accessories/providers/onboarding_provider.dart';

class OnboardingUtils {
  /// Reset onboarding state for testing purposes
  static Future<void> resetOnboarding(WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).resetOnboarding();
  }

  /// Check if user has seen onboarding
  static bool hasSeenOnboarding(WidgetRef ref) {
    return ref.read(onboardingProvider);
  }

  /// Mark onboarding as complete
  static Future<void> markOnboardingComplete(WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).markOnboardingComplete();
  }
} 