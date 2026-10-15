import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/chat_repository.dart';
import '../../domain/models/chat_message.dart';

/// Secure in-app messaging screen unlocked only after an ownership claim is verified.
class ChatScreen extends ConsumerStatefulWidget {
  final String claimId;

  const ChatScreen({super.key, required this.claimId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      claimId: widget.claimId,
      senderId: user.uid,
      senderName: user.displayName,
      text: text,
      timestamp: DateTime.now(),
    );

    _messageController.clear();
    await ref.read(chatRepositoryProvider).sendMessage(newMsg);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.claimId));
    final messages = messagesAsync.value ?? [];
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verified Handover Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('Private Peer-to-Peer', style: TextStyle(fontSize: 11, color: AppColors.mutedGreen)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Campus Handover Safety Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
              color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF0FDF4),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.mutedGreen),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safety Protocol: Meet in public campus areas (e.g. Student Center desk, Library foyer). Never share passwords or fees.',
                      style: TextStyle(fontSize: 11, color: AppColors.mutedGreen, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'Say hello to coordinate a safe campus meetup!',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: AppSpacing.screenPadding,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = currentUser != null && msg.senderId == currentUser.uid;

                        final bubbleBg = isMe
                            ? (isDark ? Colors.white : AppColors.charcoal)
                            : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight);

                        final textColor = isMe
                            ? (isDark ? AppColors.charcoal : Colors.white)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.s),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: bubbleBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    msg.senderName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                Text(
                                  msg.text,
                                  style: TextStyle(fontSize: 14, color: textColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('h:mm a').format(msg.timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? (isDark ? Colors.black54 : Colors.white70)
                                        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Message Composer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Coordinate meeting time and spot...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.mutedGreen),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
