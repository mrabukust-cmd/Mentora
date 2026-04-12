import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mentora/services/chat_service.dart';
import 'package:mentora/screens/chat/chat_models.dart';
import 'package:mentora/screens/chat/chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String currentUserId;
  final ChatService _chatService = ChatService();

  ChatListScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _chatService.streamUserConversations(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 80,
              color: Color(0xFFEEEEEE),
            ),
            itemBuilder: (context, index) {
              return _ConversationTile(
                conversation: conversations[index],
                currentUserId: currentUserId,
                chatService: _chatService,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 44,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Accept a skill exchange request\nto start chatting!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final ChatService chatService;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.chatService,
  });

  @override
  Widget build(BuildContext context) {
    final otherId = conversation.participants
        .firstWhere((id) => id != currentUserId, orElse: () => '');
    final otherName = conversation.participantNames[otherId] ?? 'User';
    final otherPhoto = conversation.participantPhotos[otherId] ?? '';
    final unread = conversation.unreadCount[currentUserId] ?? 0;
    final hasUnread = unread > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversation.id,
              currentUserId: currentUserId,
              otherUserId: otherId,
              otherUserName: otherName,
              otherUserPhoto: otherPhoto,
            ),
          ),
        );
      },
      child: Container(
        color: hasUnread
            ? const Color(0xFF6C63FF).withOpacity(0.04)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
                  backgroundImage:
                      otherPhoto.isNotEmpty ? NetworkImage(otherPhoto) : null,
                  child: otherPhoto.isEmpty
                      ? Text(
                          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF),
                          ),
                        )
                      : null,
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          hasUnread ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread
                          ? const Color(0xFF6C63FF)
                          : Colors.grey[500],
                      fontWeight: hasUnread
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Time
            Text(
              timeago.format(conversation.lastMessageTime, allowFromNow: true),
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? const Color(0xFF6C63FF) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}