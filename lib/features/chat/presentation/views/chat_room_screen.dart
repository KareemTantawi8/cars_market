import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/common/message_bubble.dart';
import '../../../../shared/widgets/common/online_indicator.dart';
import '../../../../shared/widgets/common/custom_toast.dart';
import '../../../../core/services/realtime_service.dart';
import '../cubit/chat_cubit.dart';

/// Chat Room Screen
class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    this.chatName = 'مركز النصر لقطع الغيار',
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOnline = false;
  String _displayName = '';
  String? _peerPhone;
  List<Map<String, dynamic>> _messages = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = int.tryParse(StorageService.getUserId() ?? '');
    // Defer until the widget is fully mounted so context.read is safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadChatData();
    });
  }

  Future<void> _loadChatData() async {
    final chatId = int.tryParse(widget.chatId);
    if (chatId == null) return;

    final cubit = context.read<ChatCubit>();

    // Load chat details first; only proceed if successful
    final success = await cubit.getChatDetails(chatId);
    if (!success || !mounted) return;

    // Load messages and mark as read only if chat exists
    await cubit.getChatMessages(chatId: chatId);
    if (mounted) cubit.markAsRead(chatId);

    if (!mounted) return;
    RealtimeService.instance.activeChatId = chatId;
    await RealtimeService.instance.start();
    RealtimeService.instance.subscribeChat(
      chatId,
      onMessage: (data) {
        if (!mounted) return;
        final row = _mapRealtimeMessageRow(data);
        final mid = row['id'];
        if (mid != null && _messages.any((m) => m['id'] == mid)) return;
        setState(() => _messages.insert(0, row));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      },
    );
  }

  Map<String, dynamic> _mapRealtimeMessageRow(Map<String, dynamic> data) {
    final sender = data['sender'] is Map<String, dynamic>
        ? data['sender'] as Map<String, dynamic>
        : <String, dynamic>{};
    return {
      'id': data['id'],
      'chat_id': data['chat_id'],
      'sender_id': data['sender_id'],
      'body': data['body']?.toString() ?? '',
      'is_system': false,
      'is_read': 0,
      'read_at': null,
      'created_at': data['created_at']?.toString(),
      'updated_at': data['updated_at']?.toString() ?? data['created_at']?.toString(),
      'sender': {
        'id': sender['id'],
        'name': sender['name']?.toString() ?? '',
      },
    };
  }

  @override
  void dispose() {
    final chatId = int.tryParse(widget.chatId);
    if (chatId != null) {
      RealtimeService.instance.unsubscribeChat(chatId);
      if (RealtimeService.instance.activeChatId == chatId) {
        RealtimeService.instance.activeChatId = null;
      }
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final chatId = int.tryParse(widget.chatId);
    if (chatId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Optimistic UI update - add message immediately to show it right away
    final optimisticMessage = {
      'id': DateTime.now().millisecondsSinceEpoch, // Temporary ID
      'chat_id': chatId,
      'sender_id': _currentUserId,
      'body': messageText,
      'is_system': false,
      'is_read': 0,
      'read_at': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'sender': {'id': _currentUserId, 'name': 'You'},
    };

    setState(() {
      // Add new message at the beginning (newest first, ListView reverse will show at bottom)
      _messages.insert(0, optimisticMessage);
    });

    // Scroll to bottom immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });

    // Send message via Cubit (will reload messages and replace optimistic one)
    context.read<ChatCubit>().sendMessage(
      chatId: chatId,
      body: messageText,
    );
  }

  bool _isMessageFromMe(Map<String, dynamic> message) {
    final me = _currentUserId;
    if (me == null) return false;

    bool sameId(dynamic raw) {
      if (raw is int) return raw == me;
      if (raw is num) return raw.toInt() == me;
      return raw?.toString() == me.toString();
    }

    if (sameId(message['sender_id'])) return true;

    final sender = message['sender'];
    if (sender is Map<String, dynamic>) {
      if (sameId(sender['id'])) return true;
    }
    return false;
  }

  String _peerCaption(Map<String, dynamic> message) {
    final s = message['sender'];
    if (s is Map) {
      final n = s['name']?.toString().trim() ?? '';
      if (n.isNotEmpty && n != 'You') return n;
    }
    return widget.chatName;
  }

  String? _sanitizeDialNumber(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('+')) {
      final rest = t.substring(1).replaceAll(RegExp(r'\D'), '');
      return rest.isEmpty ? null : '+$rest';
    }
    final digits = t.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }

  String? _phoneFromParticipant(dynamic raw) {
    if (raw is! Map) return null;
    final p = Map<String, dynamic>.from(raw);
    for (final key in [
      'phone',
      'mobile',
      'phone_number',
      'shop_phone',
      'shop_mobile',
    ]) {
      final v = _sanitizeDialNumber(p[key]?.toString());
      if (v != null) return v;
    }
    final user = p['user'];
    if (user is Map) {
      final u = Map<String, dynamic>.from(user);
      for (final key in ['phone', 'mobile', 'phone_number']) {
        final v = _sanitizeDialNumber(u[key]?.toString());
        if (v != null) return v;
      }
    }
    return null;
  }

  Future<void> _callPeer() async {
    final number = _peerPhone;
    if (number == null || number.isEmpty) {
      if (mounted) {
        CustomToast.showError(context, 'لا يتوفر رقم هاتف لهذا الطرف');
      }
      return;
    }
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      CustomToast.showError(context, 'تعذّر فتح تطبيق الاتصال');
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final sameDay = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      if (sameDay) {
        return DateFormat('HH:mm').format(date);
      }
      final difference = now.difference(date);
      if (difference.inDays == 1) {
        return 'أمس ${DateFormat('HH:mm').format(date)}';
      }
      if (difference.inDays < 7) {
        return DateFormat('EEE HH:mm').format(date);
      }
      return DateFormat('d/M/y HH:mm').format(date);
    } catch (_) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is ChatError) {
          // Only show error if it's not about server logging issues
          // (in that case, message might have been sent successfully)
          if (!state.message.contains('تم إرسال الرسالة ولكن حدث خطأ في السيرفر')) {
            CustomToast.showError(context, state.message);
          } else {
            // Show info message instead of error
            CustomToast.showInfo(context, 'جاري التحقق من الرسالة...');
          }
        } else if (state is MessageSent) {
          // Message sent successfully - messages will be reloaded automatically
          // Scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else if (state is ChatDetailsLoaded) {
          final userType = StorageService.getUserType();
          if (userType == AppConstants.userTypeVendor) {
            final c = state.chat['customer'];
            _displayName = c is Map ? (c['name']?.toString() ?? 'عميل') : 'عميل';
            _isOnline = c is Map ? (c['is_online'] == true) : false;
            _peerPhone = _phoneFromParticipant(c);
          } else {
            final v = state.chat['vendor'];
            _displayName =
                v is Map ? (v['company_name']?.toString() ?? 'تاجر') : 'تاجر';
            _isOnline = v is Map ? (v['is_online'] == true) : false;
            _peerPhone = _phoneFromParticipant(v);
          }
        } else if (state is MessagesLoaded) {
          setState(() {
            // API returns messages newest first, ListView with reverse:true will show newest at bottom
            _messages = List<Map<String, dynamic>>.from(state.messages);
          });
          // Scroll to bottom when new messages arrive (reverse:true means 0.0 is bottom)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
      builder: (context, state) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _callPeer,
            tooltip: 'اتصال',
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.surfaceBg,
                  ),
                  child: Icon(
                    Icons.store,
                    color: context.textSecondary,
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
                        _displayName.isNotEmpty ? _displayName : widget.chatName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                        _isOnline ? 'متصل الآن' : 'غير متصل',
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
                child: state is ChatLoading && _messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد رسائل بعد',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isSentByMe = _isMessageFromMe(message);
                              final body = message['body']?.toString() ?? '';
                              final timestamp = message['created_at']?.toString() ?? '';
                              final isSystemRaw = message['is_system'];
                              final isSystem = isSystemRaw == true ||
                                  isSystemRaw == 1 ||
                                  isSystemRaw == '1';

                              if (isSystem) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      body,
                                      style: AppTextStyles.caption.copyWith(
                                        color: context.textSecondary,
                                        fontStyle: FontStyle.italic,
                ),
                                    ),
                                  ),
                                );
                              }

                              return MessageBubble(
                                message: body,
                                timestamp: _formatTimestamp(timestamp),
                                isSentByMe: isSentByMe,
                                imageUrl: message['image_url']?.toString(),
                                peerDisplayName:
                                    isSentByMe ? null : _peerCaption(message),
                              );
                            },
            ),
          ),
          // Message Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceBg,
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
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTextStyles.input,
                      decoration: InputDecoration(
                        hintText: 'أكتب رسالة...',
                        hintStyle: AppTextStyles.inputHint,
                        filled: true,
                        fillColor: context.inputBg,
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
                        color: Colors.white,
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
      },
    );
  }
}

