import 'package:car_accessories/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/messaging_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import 'package:uuid/uuid.dart';

class SellerChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  const SellerChatScreen({
    required this.conversationId,
    required this.otherUserId,
    super.key,
  });

  @override
  ConsumerState<SellerChatScreen> createState() => _SellerChatScreenState();
}

class _SellerChatScreenState extends ConsumerState<SellerChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    final user = ref.read(currentUserProvider)!;
    final msg = MessageModel(
      id: const Uuid().v4(),
      conversationId: widget.conversationId,
      senderId: user.id,
      receiverId: widget.otherUserId,
      content: content.trim(),
      timestamp: DateTime.now(),
    );
    await MessagingService().sendMessage(msg);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider)!;
    return Scaffold(
      appBar: AppBar(title: Text('Chat with User ${widget.otherUserId}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: MessagingService().fetchMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                // Mark unread messages as read
                for (final msg in messages) {
                  if (!msg.isRead && msg.receiverId == user.id) {
                    MessagingService().markMessageAsRead(
                      widget.conversationId,
                      msg.id,
                    );
                  }
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == user.id;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg.content),
                            const SizedBox(height: 2),
                            Text(
                              TimeOfDay.fromDateTime(
                                msg.timestamp,
                              ).format(context),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
