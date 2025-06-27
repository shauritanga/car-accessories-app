import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class ErrorHandlingService {
  static final ErrorHandlingService _instance =
      ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Error types
  static const String networkError = 'network_error';
  static const String authenticationError = 'authentication_error';
  static const String databaseError = 'database_error';
  static const String validationError = 'validation_error';
  static const String permissionError = 'permission_error';
  static const String unknownError = 'unknown_error';

  // Log error with context
  Future<void> logError({
    required String error,
    required String type,
    String? userId,
    String? screen,
    String? action,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) async {
    try {
      final errorData = {
        'error': error,
        'type': type,
        'userId': userId ?? _auth.currentUser?.uid,
        'screen': screen,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'additionalData': additionalData,
        'stackTrace': stackTrace?.toString(),
        'appVersion': '1.0.0', // TODO: Get from app info
        'platform': 'flutter',
      };

      // Log to console for development
      developer.log(
        'ERROR [$type]: $error',
        name: 'ErrorHandlingService',
        error: error,
        stackTrace: stackTrace,
      );

      // Store in Firestore for production monitoring
      await _firestore.collection('error_logs').add(errorData);
    } catch (e) {
      // Fallback to console if Firestore fails
      developer.log(
        'Failed to log error: $e',
        name: 'ErrorHandlingService',
        error: e,
      );
    }
  }

  // Handle and display user-friendly error messages
  String getUserFriendlyMessage(String error, String type) {
    switch (type) {
      case networkError:
        return 'Connection error. Please check your internet connection and try again.';
      case authenticationError:
        return 'Authentication failed. Please log in again.';
      case databaseError:
        return 'Unable to load data. Please try again later.';
      case validationError:
        return 'Please check your input and try again.';
      case permissionError:
        return 'You don\'t have permission to perform this action.';
      case unknownError:
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // Show error snackbar
  void showErrorSnackBar(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action:
            actionLabel != null && onAction != null
                ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction,
                )
                : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Show error dialog
  Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAction();
                  },
                  child: Text(actionLabel),
                ),
            ],
          ),
    );
  }

  // Handle Firebase Auth errors
  String handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Handle Firestore errors
  String handleFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to access this data.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This item already exists.';
      case 'resource-exhausted':
        return 'Service limit exceeded. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed due to a precondition.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Operation is out of valid range.';
      case 'unimplemented':
        return 'This operation is not implemented.';
      case 'internal':
        return 'Internal server error. Please try again later.';
      case 'data-loss':
        return 'Data loss occurred. Please try again.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      default:
        return 'Database error. Please try again.';
    }
  }

  // Retry mechanism with exponential backoff
  Future<T> retryOperation<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          rethrow;
        }

        // Log retry attempt
        await logError(
          error: e.toString(),
          type: networkError,
          action: 'retry_attempt_$attempts',
          additionalData: {'attempt': attempts, 'maxRetries': maxRetries},
        );

        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      }
    }

    throw Exception('Operation failed after $maxRetries attempts');
  }

  // Global error handler for uncaught exceptions
  void setupGlobalErrorHandler() {
    FlutterError.onError = (FlutterErrorDetails details) async {
      await logError(
        error: details.exception.toString(),
        type: unknownError,
        screen: details.library,
        stackTrace: details.stack,
        additionalData: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };
  }

  // Validate user input
  Map<String, String> validateUserInput({
    String? email,
    String? password,
    String? name,
    String? phone,
  }) {
    final errors = <String, String>{};

    if (email != null && email.isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        errors['email'] = 'Please enter a valid email address';
      }
    }

    if (password != null && password.isNotEmpty) {
      if (password.length < 8) {
        errors['password'] = 'Password must be at least 8 characters long';
      } else if (!RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)',
      ).hasMatch(password)) {
        errors['password'] =
            'Password must contain uppercase, lowercase, and number';
      }
    }

    if (name != null && name.isNotEmpty) {
      if (name.length < 2) {
        errors['name'] = 'Name must be at least 2 characters long';
      }
    }

    if (phone != null && phone.isNotEmpty) {
      if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phone)) {
        errors['phone'] = 'Please enter a valid phone number';
      }
    }

    return errors;
  }

  // Check if error is retryable
  bool isRetryableError(String errorType) {
    return [networkError, databaseError, unknownError].contains(errorType);
  }

  // Get error analytics data
  Map<String, dynamic> getErrorAnalytics(String errorType, String error) {
    return {
      'errorType': errorType,
      'errorMessage': error,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': _auth.currentUser?.uid,
      'userEmail': _auth.currentUser?.email,
    };
  }
}

// Global error handling widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(String error)? errorWidget;

  const ErrorBoundary({super.key, required this.child, this.errorWidget});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  String? _error;

  @override
  void initState() {
    super.initState();
    ErrorHandlingService().setupGlobalErrorHandler();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget?.call(_error!) ??
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _error = null);
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
    }

    return widget.child;
  }
}
