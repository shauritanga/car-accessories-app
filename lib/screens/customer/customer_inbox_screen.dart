import 'package:car_accessories/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/messaging_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import 'customer_chat_screen.dart';
import '../../services/user_profile_service.dart';

class CustomerInboxScreen extends ConsumerWidget {
  const CustomerInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox / Messages')),
      body: StreamBuilder<List<ConversationModel>>(
        stream: MessagingService().fetchConversations(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }
          final conversations = snapshot.data!;
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final convo = conversations[index];
              final otherId = convo.participantIds.firstWhere(
                (id) => id != user.id,
              );
              final lastMsg = convo.lastMessage;
              final lastTs = convo.lastUpdated;
              return FutureBuilder<UserModel?>(
                future: UserProfileService().getUserProfile(otherId),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data;
                  return ListTile(
                    leading:
                        (userData?.profileImageUrl != null &&
                                userData!.profileImageUrl!.isNotEmpty)
                            ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                userData.profileImageUrl!,
                              ),
                            )
                            : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(userData?.name ?? 'User $otherId'),
                    subtitle: Text(lastMsg),
                    trailing:
                        lastTs != null
                            ? Text(
                              TimeOfDay.fromDateTime(lastTs).format(context),
                            )
                            : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CustomerChatScreen(
                                conversationId: convo.id,
                                otherUserId: otherId,
                              ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
