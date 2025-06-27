import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State class to track both loading and onboarding status
class OnboardingState {
  final bool hasSeenOnboarding;
  final bool isLoading;

  const OnboardingState({
    required this.hasSeenOnboarding,
    required this.isLoading,
  });

  OnboardingState copyWith({bool? hasSeenOnboarding, bool? isLoading}) {
    return OnboardingState(
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier()
    : super(const OnboardingState(hasSeenOnboarding: false, isLoading: true)) {
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      state = OnboardingState(
        hasSeenOnboarding: hasSeenOnboarding,
        isLoading: false,
      );
    } catch (e) {
      // If there's an error, assume first time user
      state = const OnboardingState(hasSeenOnboarding: false, isLoading: false);
    }
  }

  Future<void> markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);

      state = state.copyWith(hasSeenOnboarding: true);
    } catch (e) {
      // Handle error silently, but update state
      state = state.copyWith(hasSeenOnboarding: true);
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', false);

      state = state.copyWith(hasSeenOnboarding: false);
    } catch (e) {
      // Handle error silently, but update state
      state = state.copyWith(hasSeenOnboarding: false);
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
      (ref) => OnboardingNotifier(),
    );

// Convenience provider for just the boolean value (for backward compatibility)
final hasSeenOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).hasSeenOnboarding;
});

// Provider to check if onboarding data is still loading
final onboardingLoadingProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isLoading;
});
