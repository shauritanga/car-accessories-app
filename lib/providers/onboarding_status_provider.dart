import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Alternative provider using FutureProvider for better async handling
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    print('OnboardingStatusProvider: hasSeenOnboarding = $hasSeenOnboarding');
    return hasSeenOnboarding;
  } catch (e) {
    print('OnboardingStatusProvider: Error loading status - $e');
    // If there's an error, assume first time user
    return false;
  }
});

/// Provider to mark onboarding as complete
final onboardingActionsProvider = Provider((ref) => OnboardingActions(ref));

class OnboardingActions {
  final Ref _ref;

  OnboardingActions(this._ref);

  Future<void> markOnboardingComplete() async {
    try {
      print('OnboardingActions: Marking onboarding as complete');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      print('OnboardingActions: Successfully saved onboarding completion');

      // Invalidate the provider to refresh the state
      _ref.invalidate(onboardingStatusProvider);
    } catch (e) {
      // Handle error silently
      print('Error marking onboarding complete: $e');
    }
  }

  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', false);

      // Invalidate the provider to refresh the state
      _ref.invalidate(onboardingStatusProvider);
    } catch (e) {
      // Handle error silently
      print('Error resetting onboarding: $e');
    }
  }
}
