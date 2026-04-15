import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/routes/app_routes.dart';
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

  /// Phone number passed from the chat list (pre-fetched from inbox data).
  final String? peerPhone;

  /// Whether the peer vendor is verified (pre-fetched from inbox/caller data).
  final bool peerIsVerified;

  /// Avatar URL of the peer (pre-fetched from inbox/caller data).
  final String? peerAvatarUrl;

  /// Vendor record ID (vendors.id) — used by customers to navigate to the vendor profile.
  final int? peerVendorId;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    this.chatName = 'مركز النصر لقطع الغيار',
    this.peerPhone,
    this.peerIsVerified = false,
    this.peerAvatarUrl,
    this.peerVendorId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOnline = false;
  bool _isVerified = false;
  String _displayName = '';
  String? _peerPhone;
  String? _peerAvatarUrl;
  /// Vendor record ID (vendors.id) — to navigate to vendor profile.
  int? _peerVendorId;
  /// Fallback: user-account ID if vendor record ID is unavailable.
  int? _peerUserId;
  /// Last chat details from API (for phone fallbacks if nested shape differs).
  Map<String, dynamic>? _chatDetailsSnapshot;
  List<Map<String, dynamic>> _messages = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = int.tryParse(StorageService.getUserId() ?? '');
    // Pre-populate from inbox data (available immediately, before API returns).
    if (widget.peerPhone != null && widget.peerPhone!.trim().isNotEmpty) {
      _peerPhone = widget.peerPhone!.trim();
    }
    _isVerified = widget.peerIsVerified;
    if (widget.peerAvatarUrl != null && widget.peerAvatarUrl!.trim().isNotEmpty) {
      _peerAvatarUrl = _resolveStorageUrl(widget.peerAvatarUrl!.trim());
    }
    if (widget.peerVendorId != null && widget.peerVendorId! > 0) {
      _peerVendorId = widget.peerVendorId;
    }
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
      'tel',
      'telephone',
      'contact_phone',
      'primary_phone',
      'shop_phone',
      'shop_mobile',
      'company_phone',
      'business_phone',
    ]) {
      final v = _sanitizeDialNumber(p[key]?.toString());
      if (v != null) return v;
    }
    for (final nestKey in ['user', 'profile', 'account', 'owner']) {
      final nest = p[nestKey];
      if (nest is Map) {
        final inner = Map<String, dynamic>.from(nest);
        for (final key in ['phone', 'mobile', 'phone_number']) {
          final v = _sanitizeDialNumber(inner[key]?.toString());
          if (v != null) return v;
        }
      }
    }
    return null;
  }

  dynamic _peerParticipantFromChat(Map<String, dynamic> chat) {
    // New unified API returns a single `participant` key (the other party).
    final p = chat['participant'];
    if (p != null) return p;
    // Legacy fallback: vendor/customer separated by user type.
    final userType = StorageService.getUserType();
    if (userType == AppConstants.userTypeVendor) {
      return chat['customer'] ?? chat['buyer'] ?? chat['client'];
    }
    return chat['vendor'] ?? chat['seller'] ?? chat['shop'];
  }

  String? _phoneFromChatEnvelope(Map<String, dynamic> chat) {
    final peer = _peerParticipantFromChat(chat);
    var n = _phoneFromParticipant(peer);
    if (n != null) return n;
    for (final key in [
      'peer_phone',
      'counterparty_phone',
      'other_party_phone',
      'contact_phone',
    ]) {
      n = _sanitizeDialNumber(chat[key]?.toString());
      if (n != null) return n;
    }
    final sr = chat['search_request'];
    if (sr is Map) {
      for (final key in ['phone', 'contact_phone', 'customer_phone']) {
        n = _sanitizeDialNumber(
          Map<String, dynamic>.from(sr)[key]?.toString(),
        );
        if (n != null) return n;
      }
    }
    return null;
  }

  void _applyChatDetails(Map<String, dynamic> chat) {
    final userType = StorageService.getUserType();
    final peer = _peerParticipantFromChat(chat);
    String displayName;
    bool online;
    bool verified;
    if (userType == AppConstants.userTypeVendor) {
      // Vendor sees customer
      displayName = peer is Map
          ? (peer['name']?.toString() ?? 'عميل')
          : 'عميل';
      online = peer is Map ? (peer['is_online'] == true) : false;
      verified = false;
    } else {
      // Customer sees vendor: prefer company_name, fallback to name
      displayName = peer is Map
          ? (peer['company_name']?.toString() ??
              peer['name']?.toString() ??
              'تاجر')
          : 'تاجر';
      online = peer is Map ? (peer['is_online'] == true) : false;
      verified = peer is Map
          ? (peer['is_verified'] == true ||
              peer['verified'] == true ||
              peer['is_certified'] == true)
          : false;
    }
    final phone = _phoneFromChatEnvelope(chat);
    final avatarUrl = _avatarFromParticipant(peer);

    // Extract vendor record ID and user account ID for profile navigation.
    int? vendorId;
    int? userId;
    if (userType != AppConstants.userTypeVendor && peer is Map) {
      final pm = Map<String, dynamic>.from(peer);
      final rawId = pm['id'];
      if (rawId is int) vendorId = rawId;
      else if (rawId is num) vendorId = rawId.toInt();
      else vendorId = int.tryParse(rawId?.toString() ?? '');

      final rawUid = pm['user_id'];
      if (rawUid is int) userId = rawUid;
      else if (rawUid is num) userId = rawUid.toInt();
      else userId = int.tryParse(rawUid?.toString() ?? '');
    }

    setState(() {
      _chatDetailsSnapshot = chat;
      _displayName = displayName;
      _isOnline = online;
      _isVerified = verified;
      _peerPhone = phone ?? _peerPhone;
      if (avatarUrl != null) _peerAvatarUrl = avatarUrl;
      if (vendorId != null && vendorId > 0) _peerVendorId = vendorId;
      if (userId != null && userId > 0) _peerUserId = userId;
    });
  }

  /// Navigate to the vendor profile (customers only).
  void _openVendorProfile(BuildContext context) {
    final userType = StorageService.getUserType();
    if (userType == AppConstants.userTypeVendor) return;
    final vid = _peerVendorId;
    final uid = _peerUserId;
    if (vid != null && vid > 0) {
      Navigator.pushNamed(context, AppRoutes.vendorProfile, arguments: {
        'vendorId': vid.toString(),
        'vendorName': _displayName.isNotEmpty ? _displayName : widget.chatName,
        'vendorProfileByUserId': false,
      });
    } else if (uid != null && uid > 0) {
      Navigator.pushNamed(context, AppRoutes.vendorProfile, arguments: {
        'vendorId': uid.toString(),
        'vendorName': _displayName.isNotEmpty ? _displayName : widget.chatName,
        'vendorProfileByUserId': true,
      });
    }
  }

  static String _resolveStorageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = AppConstants.storageBaseUrl.endsWith('/')
        ? AppConstants.storageBaseUrl.substring(0, AppConstants.storageBaseUrl.length - 1)
        : AppConstants.storageBaseUrl;
    final sanitized = path.startsWith('/') ? path.substring(1) : path;
    return '$base/$sanitized';
  }

  String? _avatarFromParticipant(dynamic raw) {
    if (raw is! Map) return null;
    final p = Map<String, dynamic>.from(raw);
    for (final key in [
      'avatar',
      'image_url',
      'image',
      'logo',
      'photo',
      'profile_image',
      'profile_image_url',
    ]) {
      final v = p[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return _resolveStorageUrl(v);
    }
    // Also check nested user/profile objects (e.g. vendor.user.profile_image_url)
    for (final nestKey in ['user', 'profile', 'account']) {
      final nest = p[nestKey];
      if (nest is Map) {
        final nm = Map<String, dynamic>.from(nest);
        for (final key in [
          'avatar',
          'image_url',
          'image',
          'photo',
          'profile_image',
          'profile_image_url',
        ]) {
          final v = nm[key]?.toString().trim();
          if (v != null && v.isNotEmpty) return _resolveStorageUrl(v);
        }
      }
    }
    return null;
  }

  Widget _buildPeerAvatar(BuildContext context, {double size = 40}) {
    final isVendorUser = StorageService.getUserType() == AppConstants.userTypeVendor;
    final fallbackIcon = isVendorUser ? Icons.person : Icons.store;
    final url = _peerAvatarUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.surfaceBg,
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Icon(
                  fallbackIcon,
                  color: context.textSecondary,
                  size: size * 0.55,
                ),
                errorWidget: (_, __, ___) => Icon(
                  fallbackIcon,
                  color: context.textSecondary,
                  size: size * 0.55,
                ),
              )
            : Icon(
                fallbackIcon,
                color: context.textSecondary,
                size: size * 0.55,
              ),
      ),
    );
  }

  Future<void> _callPeer() async {
    var number = _peerPhone;
    if ((number == null || number.isEmpty) && _chatDetailsSnapshot != null) {
      number = _phoneFromChatEnvelope(_chatDetailsSnapshot!);
    }
    final uri = number != null && number.isNotEmpty
        ? Uri.parse('tel:$number')
        : null;
    if (uri == null) {
      if (mounted) {
        CustomToast.showError(context, 'لا يتوفر رقم هاتف لهذا الطرف');
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          final map = state.chat['data'] is Map<String, dynamic>
              ? state.chat['data'] as Map<String, dynamic>
              : state.chat;
          _applyChatDetails(Map<String, dynamic>.from(map));
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
        title: GestureDetector(
          onTap: () => _openVendorProfile(context),
          child: Row(
          children: [
            // Profile Picture
            Stack(
              children: [
                _buildPeerAvatar(context, size: 40),
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _displayName.isNotEmpty
                              ? _displayName
                              : widget.chatName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppColors.primaryColor,
                          size: 16,
                        ),
                      ],
                    ],
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
                                senderImageUrl: isSentByMe ? null : _peerAvatarUrl,
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

