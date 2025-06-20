import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(0, title, body, details);
  }

  // Order-specific notifications
  Future<void> sendOrderConfirmation(OrderModel order) async {
    try {
      await _showOrderNotification(
        id: order.id.hashCode,
        title: 'Order Confirmed!',
        body:
            'Your order #${order.shortId} has been placed successfully. Total: ${order.formattedTotal}',
        payload: 'order:${order.id}',
        channelId: 'order_confirmations',
        channelName: 'Order Confirmations',
      );

      await _saveNotificationToDatabase(
        userId: order.customerId,
        title: 'Order Confirmed',
        body: 'Your order #${order.shortId} has been placed successfully',
        type: 'order_confirmation',
        data: {'orderId': order.id},
      );
    } catch (e) {
      print('Error sending order confirmation: $e');
    }
  }

  Future<void> sendOrderStatusUpdate(
    OrderModel order,
    OrderStatusUpdate statusUpdate,
  ) async {
    try {
      String title = '';
      String body = '';

      switch (order.status.toLowerCase()) {
        case 'processing':
          title = 'Order Processing';
          body = 'Your order #${order.shortId} is now being processed';
          break;
        case 'shipped':
          title = 'Order Shipped!';
          body =
              'Your order #${order.shortId} has been shipped. ${order.trackingNumber != null ? 'Tracking: ${order.trackingNumber}' : ''}';
          break;
        case 'delivered':
          title = 'Order Delivered!';
          body = 'Your order #${order.shortId} has been delivered successfully';
          break;
        case 'cancelled':
          title = 'Order Cancelled';
          body = 'Your order #${order.shortId} has been cancelled';
          break;
        default:
          title = 'Order Update';
          body =
              'Your order #${order.shortId} status: ${order.statusDisplayName}';
      }

      await _showOrderNotification(
        id: order.id.hashCode + order.status.hashCode,
        title: title,
        body: body,
        payload: 'order:${order.id}',
        channelId: 'order_updates',
        channelName: 'Order Updates',
      );

      await _saveNotificationToDatabase(
        userId: order.customerId,
        title: title,
        body: body,
        type: 'order_status_update',
        data: {'orderId': order.id, 'status': order.status},
      );
    } catch (e) {
      print('Error sending status update notification: $e');
    }
  }

  Future<void> sendDeliveryReminder(OrderModel order) async {
    try {
      if (order.estimatedDeliveryDate == null) return;

      final title = 'Delivery Today!';
      final body =
          'Your order #${order.shortId} is expected to be delivered today';

      await _showOrderNotification(
        id: order.id.hashCode + 'delivery'.hashCode,
        title: title,
        body: body,
        payload: 'order:${order.id}',
        channelId: 'delivery_reminders',
        channelName: 'Delivery Reminders',
      );

      await _saveNotificationToDatabase(
        userId: order.customerId,
        title: title,
        body: body,
        type: 'delivery_reminder',
        data: {'orderId': order.id},
      );
    } catch (e) {
      print('Error sending delivery reminder: $e');
    }
  }

  Future<void> _showOrderNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required String channelId,
    required String channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for $channelName',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> _saveNotificationToDatabase({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving notification to database: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.startsWith('order:')) {
      final orderId = payload.substring(6);
      // Handle navigation to order details
      print('Navigate to order: $orderId');
    }
  }

  // Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
