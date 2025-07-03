import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message (creates conversation if needed)
  Future<void> sendMessage(MessageModel message) async {
    await _firestore
        .collection('conversations')
        .doc(message.conversationId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
    // Update conversation metadata
    await _firestore.collection('conversations').doc(message.conversationId).set({
      'participantIds': [message.senderId, message.receiverId],
      'lastMessage': message.content,
      'lastUpdated': Timestamp.fromDate(message.timestamp),
    }, SetOptions(merge: true));
  }

  // Fetch messages for a conversation (ordered by timestamp)
  Stream<List<MessageModel>> fetchMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Fetch all conversations for a user (customer or seller)
  Stream<List<ConversationModel>> fetchConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Mark a message as read
  Future<void> markMessageAsRead(String conversationId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // Start a new conversation (returns conversationId)
  Future<String> startConversation(List<String> participantIds) async {
    // Check if conversation already exists
    final query = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContainsAny: participantIds)
        .get();
    for (final doc in query.docs) {
      final data = doc.data();
      final ids = List<String>.from(data['participantIds'] ?? []);
      if (ids.toSet().containsAll(participantIds) && ids.length == participantIds.length) {
        return doc.id;
      }
    }
    // Create new conversation
    final docRef = _firestore.collection('conversations').doc();
    await docRef.set({
      'participantIds': participantIds,
      'lastMessage': '',
      'lastUpdated': Timestamp.now(),
    });
    return docRef.id;
  }
} 