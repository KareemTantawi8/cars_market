import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/common/message_bubble.dart';
import '../../../../shared/widgets/common/online_indicator.dart';
import '../../../../shared/widgets/common/send_message_dialog.dart';

/// Chat Room Screen
class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String vendorName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    this.vendorName = 'مركز النصر لقطع الغيار',
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final bool _isOnline = true;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    // TODO: Send message via Cubit/API
    print('Sending message: ${_messageController.text}');
    _messageController.clear();
    
    // Scroll to bottom
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Handle phone call
            },
          ),
        ],
        title: Row(
          children: [
            // Profile Picture
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceColor,
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                if (_isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: OnlineIndicator(isOnline: true, size: 12),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.vendorName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'متصل الآن',
                    style: AppTextStyles.caption.copyWith(
                      color: _isOnline ? AppColors.online : AppColors.offline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Date Separator
                const DateSeparator(date: 'اليوم'),
                
                // Business Message 1
                MessageBubble(
                  message:
                      'أهلاً بك يا فندم في مركز النصر. كيف يمكننا مساعدتك اليوم بخصوص قطع الغيار؟',
                  timestamp: 'AM 10:42',
                  isSentByMe: false,
                ),
                
                // User Message 1
                MessageBubble(
                  message: 'هل متوفر مساعدين أمامين لانسر بومة موديل 2008؟',
                  timestamp: 'AM 10:45',
                  isSentByMe: true,
                ),
                
                // Business Message 2
                MessageBubble(
                  message:
                      'نعم يا فندم متوفر نوعين، الأصلي كيب (KYB) استيراد الخارج، وفي نوع صيني جديد بجودة عالية. تحب أصورلك القطعة المتوفرة حالياً؟',
                  timestamp: 'AM 10:46',
                  isSentByMe: false,
                ),
                
                // User Message 2
                MessageBubble(
                  message:
                      'يا ريت، ومحتاج أعرف السعر للاثنين وضمان الاستبدال قد إيه؟',
                  timestamp: 'AM 10:48',
                  isSentByMe: true,
                ),
                
                // Business Image Message
                MessageBubble(
                  message: '',
                  timestamp: 'AM 10:50',
                  isSentByMe: false,
                  imageUrl:
                      'https://images.unsplash.com/photo-1486754735734-325b5831c3ad?w=400',
                ),
              ],
            ),
          ),
          
          // Message Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Gallery Icon
                  IconButton(
                    icon: const Icon(
                      Icons.image,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      // TODO: Pick image from gallery
                    },
                  ),
                  // Message Input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTextStyles.input,
                      decoration: InputDecoration(
                        hintText: 'أكتب رسالة...',
                        hintStyle: AppTextStyles.inputHint,
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

