import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'error_handling_service.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final ErrorHandlingService _errorHandler = ErrorHandlingService();

  // Performance metrics
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<Duration>> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, int> _errorCounts = {};

  // App lifecycle tracking
  DateTime? _appStartTime;
  DateTime? _lastActiveTime;
  bool _isAppActive = true;

  // Initialize monitoring
  Future<void> initialize() async {
    _appStartTime = DateTime.now();
    _lastActiveTime = DateTime.now();

    // Set up periodic metrics collection
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _collectMetrics();
    });

    // Set up app lifecycle monitoring
    _setupAppLifecycleMonitoring();

    // Log app start
    await logEvent('app_started', {
      'timestamp': DateTime.now().toIso8601String(),
      'userId': _auth.currentUser?.uid,
      'userEmail': _auth.currentUser?.email,
    });
  }

  // Log custom events
  Future<void> logEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      // Log to Firebase Analytics
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters.map(
          (key, value) => MapEntry(key, value as Object),
        ),
      );

      // Log to Firestore for custom analytics
      await _firestore.collection('analytics_events').add({
        'eventName': eventName,
        'parameters': parameters,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
        'userEmail': _auth.currentUser?.email,
        'sessionId': _getSessionId(),
      });

      // Log to console for development
      developer.log(
        'EVENT: $eventName',
        name: 'MonitoringService',
        error: parameters.toString(),
      );
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'monitoring_error',
        action: 'log_event',
        additionalData: {'eventName': eventName},
      );
    }
  }

  // Start performance tracking
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;
  }

  // End performance tracking
  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationName] ??= [];
      _operationDurations[operationName]!.add(duration);
      _operationStartTimes.remove(operationName);
    }
  }

  // Track user engagement
  Future<void> trackUserEngagement({
    required String screen,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    await logEvent('user_engagement', {
      'screen': screen,
      'action': action,
      'parameters': parameters,
      'sessionDuration': _getSessionDuration().inSeconds,
    });
  }

  // Track API calls
  Future<void> trackApiCall({
    required String endpoint,
    required String method,
    required int statusCode,
    required Duration duration,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
  }) async {
    await logEvent('api_call', {
      'endpoint': endpoint,
      'method': method,
      'statusCode': statusCode,
      'duration': duration.inMilliseconds,
      'requestData': requestData,
      'responseData': responseData,
    });

    // Track performance
    if (statusCode >= 400) {
      _errorCounts[endpoint] = (_errorCounts[endpoint] ?? 0) + 1;
    }
  }

  // Track database operations
  Future<void> trackDatabaseOperation({
    required String operation,
    required String collection,
    required Duration duration,
    bool isSuccess = true,
    String? error,
  }) async {
    await logEvent('database_operation', {
      'operation': operation,
      'collection': collection,
      'duration': duration.inMilliseconds,
      'isSuccess': isSuccess,
      'error': error,
    });
  }

  // Track user actions
  Future<void> trackUserAction({
    required String action,
    required String screen,
    Map<String, dynamic>? parameters,
  }) async {
    await logEvent('user_action', {
      'action': action,
      'screen': screen,
      'parameters': parameters,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Track app performance
  Future<void> trackAppPerformance({
    required String metric,
    required double value,
    String? unit,
  }) async {
    await logEvent('app_performance', {
      'metric': metric,
      'value': value,
      'unit': unit,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Track error with context
  Future<void> trackError({
    required String error,
    required String type,
    String? screen,
    String? action,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) async {
    // Increment error count
    _errorCounts[type] = (_errorCounts[type] ?? 0) + 1;

    await logEvent('error_occurred', {
      'error': error,
      'type': type,
      'screen': screen,
      'action': action,
      'context': context,
      'stackTrace': stackTrace?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Collect and send metrics
  Future<void> _collectMetrics() async {
    try {
      final metrics = {
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
        'sessionId': _getSessionId(),
        'sessionDuration': _getSessionDuration().inSeconds,
        'operationCounts': _operationCounts,
        'errorCounts': _errorCounts,
        'averageOperationDurations': _calculateAverageDurations(),
        'appUptime': _getAppUptime().inMinutes,
        'lastActiveTime': _lastActiveTime?.toIso8601String(),
      };

      await _firestore.collection('performance_metrics').add(metrics);

      // Reset counters
      _operationCounts.clear();
      _errorCounts.clear();
      _operationDurations.clear();
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'metrics_collection_error',
        action: 'collect_metrics',
      );
    }
  }

  // Calculate average operation durations
  Map<String, double> _calculateAverageDurations() {
    final averages = <String, double>{};

    for (final entry in _operationDurations.entries) {
      if (entry.value.isNotEmpty) {
        final totalDuration = entry.value.fold<Duration>(
          Duration.zero,
          (total, duration) => total + duration,
        );
        averages[entry.key] = totalDuration.inMilliseconds / entry.value.length;
      }
    }

    return averages;
  }

  // Get session ID
  String _getSessionId() {
    return '${_auth.currentUser?.uid ?? 'anonymous'}_${_appStartTime?.millisecondsSinceEpoch ?? 0}';
  }

  // Get session duration
  Duration _getSessionDuration() {
    if (_appStartTime == null) return Duration.zero;
    return DateTime.now().difference(_appStartTime!);
  }

  // Get app uptime
  Duration _getAppUptime() {
    if (_appStartTime == null) return Duration.zero;
    return DateTime.now().difference(_appStartTime!);
  }

  // Set up app lifecycle monitoring
  void _setupAppLifecycleMonitoring() {
    // This would typically be integrated with Flutter's WidgetsBindingObserver
    // For now, we'll use a simple timer-based approach
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isAppActive) {
        _lastActiveTime = DateTime.now();
      }
    });
  }

  // Mark app as active/inactive
  void setAppActive(bool isActive) {
    _isAppActive = isActive;
    if (isActive) {
      _lastActiveTime = DateTime.now();
    }
  }

  // Get real-time analytics
  Future<Map<String, dynamic>> getRealTimeAnalytics() async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      // Get recent events
      final eventsSnapshot =
          await _firestore
              .collection('analytics_events')
              .where('timestamp', isGreaterThan: oneHourAgo)
              .get();

      // Get recent errors
      final errorsSnapshot =
          await _firestore
              .collection('error_logs')
              .where('timestamp', isGreaterThan: oneHourAgo)
              .get();

      // Get performance metrics
      final metricsSnapshot =
          await _firestore
              .collection('performance_metrics')
              .where('timestamp', isGreaterThan: oneHourAgo)
              .get();

      return {
        'eventsCount': eventsSnapshot.docs.length,
        'errorsCount': errorsSnapshot.docs.length,
        'metricsCount': metricsSnapshot.docs.length,
        'activeUsers': _getActiveUsersCount(eventsSnapshot.docs),
        'topEvents': _getTopEvents(eventsSnapshot.docs),
        'topErrors': _getTopErrors(errorsSnapshot.docs),
        'averageResponseTime': _calculateAverageResponseTime(
          metricsSnapshot.docs,
        ),
      };
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'analytics_error',
        action: 'get_real_time_analytics',
      );
      rethrow;
    }
  }

  // Get active users count
  int _getActiveUsersCount(List<QueryDocumentSnapshot> events) {
    final activeUsers = <String>{};
    for (final event in events) {
      final data = event.data() as Map<String, dynamic>?;
      if (data != null) {
        final userId = data['userId'] as String?;
        if (userId != null) {
          activeUsers.add(userId);
        }
      }
    }
    return activeUsers.length;
  }

  // Get top events
  List<Map<String, dynamic>> _getTopEvents(List<QueryDocumentSnapshot> events) {
    final eventCounts = <String, int>{};
    for (final event in events) {
      final data = event.data() as Map<String, dynamic>?;
      if (data != null) {
        final eventName = data['eventName'] as String?;
        if (eventName != null) {
          eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
        }
      }
    }

    final sortedEvents =
        eventCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEvents
        .take(10)
        .map((entry) => {'eventName': entry.key, 'count': entry.value})
        .toList();
  }

  // Get top errors
  List<Map<String, dynamic>> _getTopErrors(List<QueryDocumentSnapshot> errors) {
    final errorCounts = <String, int>{};
    for (final error in errors) {
      final data = error.data() as Map<String, dynamic>?;
      if (data != null) {
        final errorType = data['type'] as String?;
        if (errorType != null) {
          errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
        }
      }
    }

    final sortedErrors =
        errorCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return sortedErrors
        .take(10)
        .map((entry) => {'errorType': entry.key, 'count': entry.value})
        .toList();
  }

  // Calculate average response time
  double _calculateAverageResponseTime(List<QueryDocumentSnapshot> metrics) {
    if (metrics.isEmpty) return 0.0;

    double totalResponseTime = 0.0;
    int count = 0;

    for (final metric in metrics) {
      final data = metric.data() as Map<String, dynamic>?;
      if (data != null) {
        final avgDurations =
            data['averageOperationDurations'] as Map<String, dynamic>?;
        if (avgDurations != null) {
          for (final duration in avgDurations.values) {
            if (duration is double) {
              totalResponseTime += duration;
              count++;
            }
          }
        }
      }
    }

    return count > 0 ? totalResponseTime / count : 0.0;
  }

  // Create custom dashboard
  Future<Map<String, dynamic>> createCustomDashboard({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? metrics,
  }) async {
    try {
      final dashboard = <String, dynamic>{
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'metrics': metrics ?? ['events', 'errors', 'performance', 'users'],
        'data': <String, dynamic>{},
      };

      // Get events data
      if (metrics?.contains('events') != false) {
        final eventsSnapshot =
            await _firestore
                .collection('analytics_events')
                .where('timestamp', isGreaterThanOrEqualTo: startDate)
                .where('timestamp', isLessThanOrEqualTo: endDate)
                .get();
        dashboard['data']['events'] = _processEventsData(eventsSnapshot.docs);
      }

      // Get errors data
      if (metrics?.contains('errors') != false) {
        final errorsSnapshot =
            await _firestore
                .collection('error_logs')
                .where('timestamp', isGreaterThanOrEqualTo: startDate)
                .where('timestamp', isLessThanOrEqualTo: endDate)
                .get();
        dashboard['data']['errors'] = _processErrorsData(errorsSnapshot.docs);
      }

      // Get performance data
      if (metrics?.contains('performance') != false) {
        final performanceSnapshot =
            await _firestore
                .collection('performance_metrics')
                .where('timestamp', isGreaterThanOrEqualTo: startDate)
                .where('timestamp', isLessThanOrEqualTo: endDate)
                .get();
        dashboard['data']['performance'] = _processPerformanceData(
          performanceSnapshot.docs,
        );
      }

      return dashboard;
    } catch (e) {
      await _errorHandler.logError(
        error: e.toString(),
        type: 'dashboard_error',
        action: 'create_custom_dashboard',
      );
      rethrow;
    }
  }

  // Process events data
  Map<String, dynamic> _processEventsData(List<QueryDocumentSnapshot> events) {
    final eventCounts = <String, int>{};
    final userCounts = <String, int>{};
    final screenCounts = <String, int>{};

    for (final event in events) {
      final data = event.data() as Map<String, dynamic>;

      // Count events by type
      final eventName = data['eventName'] as String?;
      if (eventName != null) {
        eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
      }

      // Count unique users
      final userId = data['userId'] as String?;
      if (userId != null) {
        userCounts[userId] = (userCounts[userId] ?? 0) + 1;
      }

      // Count screen visits
      final parameters = data['parameters'] as Map<String, dynamic>?;
      final screen = parameters?['screen'] as String?;
      if (screen != null) {
        screenCounts[screen] = (screenCounts[screen] ?? 0) + 1;
      }
    }

    return {
      'totalEvents': events.length,
      'uniqueUsers': userCounts.length,
      'eventCounts': eventCounts,
      'screenCounts': screenCounts,
    };
  }

  // Process errors data
  Map<String, dynamic> _processErrorsData(List<QueryDocumentSnapshot> errors) {
    final errorCounts = <String, int>{};
    final userErrorCounts = <String, int>{};

    for (final error in errors) {
      final data = error.data() as Map<String, dynamic>;

      final errorType = data['type'] as String?;
      if (errorType != null) {
        errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
      }

      final userId = data['userId'] as String?;
      if (userId != null) {
        userErrorCounts[userId] = (userErrorCounts[userId] ?? 0) + 1;
      }
    }

    return {
      'totalErrors': errors.length,
      'errorCounts': errorCounts,
      'userErrorCounts': userErrorCounts,
    };
  }

  // Process performance data
  Map<String, dynamic> _processPerformanceData(
    List<QueryDocumentSnapshot> metrics,
  ) {
    if (metrics.isEmpty) {
      return {
        'averageResponseTime': 0.0,
        'totalOperations': 0,
        'errorRate': 0.0,
      };
    }

    double totalResponseTime = 0.0;
    int totalOperations = 0;
    int totalErrors = 0;

    for (final metric in metrics) {
      final data = metric.data() as Map<String, dynamic>;

      final operationCounts = data['operationCounts'] as Map<String, dynamic>?;
      if (operationCounts != null) {
        for (final count in operationCounts.values) {
          if (count is int) {
            totalOperations += count;
          }
        }
      }

      final errorCounts = data['errorCounts'] as Map<String, dynamic>?;
      if (errorCounts != null) {
        for (final count in errorCounts.values) {
          if (count is int) {
            totalErrors += count;
          }
        }
      }

      final avgDurations =
          data['averageOperationDurations'] as Map<String, dynamic>?;
      if (avgDurations != null) {
        for (final duration in avgDurations.values) {
          if (duration is double) {
            totalResponseTime += duration;
          }
        }
      }
    }

    return {
      'averageResponseTime':
          totalOperations > 0 ? totalResponseTime / totalOperations : 0.0,
      'totalOperations': totalOperations,
      'errorRate':
          totalOperations > 0 ? (totalErrors / totalOperations) * 100 : 0.0,
    };
  }
}
