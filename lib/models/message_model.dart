import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String docId) {
    return MessageModel(
      id: docId,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String lastMessage;
  final DateTime lastUpdated;

  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastUpdated,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> data, String docId) {
    return ConversationModel(
      id: docId,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
} 