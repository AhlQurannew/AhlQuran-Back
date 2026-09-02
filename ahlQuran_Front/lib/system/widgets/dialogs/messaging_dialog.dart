import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:developer' as dev;
import '../../new_models/message.dart';
import '../../services/api_client.dart';
import '../../services/network/api_endpoints.dart';
import '../../utils/snackbar_helper.dart';
import '../../../controllers/profile_controller.dart';

class MessagingDialog extends StatefulWidget {
  const MessagingDialog({super.key});

  @override
  State<MessagingDialog> createState() => _MessagingDialogState();
}

class _MessagingDialogState extends State<MessagingDialog> {
  List<Message> messages = [];
  bool isLoading = true;
  bool isSending = false;
  Timer? _pollingTimer;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SenderRole? userRole;
  String userName = '';
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadMessages();
    _startPolling();
  }

  void _initializeUser() {
    try {
      final profileController = Get.find<ProfileController>();
      userName =
          '${profileController.firstName.value} ${profileController.lastName.value}';
      currentUserId = profileController.userId.value;

      // Determine user role
      final role = profileController.userRole.value.toLowerCase();
      if (role == 'teacher') {
        userRole = SenderRole.teacher;
      } else if (role == 'supervisor') {
        userRole = SenderRole.supervisor;
      } else if (role == 'president') {
        userRole = SenderRole.president;
      }

      dev.log(
          'User initialized: $userName (ID: $currentUserId), Role: $userRole');
    } catch (e) {
      dev.log('Error initializing user: $e');
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadMessages(silent: true);
      }
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          isLoading = true;
        });
      }

      final response = await ApiService.fetchObject(
        ApiEndpoints.getRecentMessages,
        MessageList.fromJson,
      );

      dev.log('Loaded ${response.messages.length} messages');
      if (response.messages.isNotEmpty) {
        dev.log(
            'First message raw data check: senderId=${response.messages.first.senderId}');
      }

      if (mounted) {
        setState(() {
          messages = response.messages;
          isLoading = false;
        });

        // Auto-scroll to bottom on new messages
        if (_scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      dev.log('Error loading messages: $e');
      if (!silent && mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      showErrorSnackbar('الرجاء كتابة رسالة', context: context);
      return;
    }

    if (userRole == null) {
      showErrorSnackbar('لم يتم تحديد دورك', context: context);
      return;
    }

    dev.log('Sending message as: userName=$userName, userRole=$userRole');

    setState(() {
      isSending = true;
    });

    try {
      final newMessage = Message(
        senderName: userName,
        senderRole: userRole!,
        message: _messageController.text.trim(),
      );

      dev.log(
          'Message object: senderName=${newMessage.senderName}, senderRole=${newMessage.senderRole}');

      await ApiService.post(
        ApiEndpoints.createMessage,
        newMessage.toJson(),
        Message.fromJson,
      );

      _messageController.clear();
      await _loadMessages(silent: true);

      if (mounted) {
        showSuccessSnackbar('تم إرسال الرسالة', context: context);
      }
    } catch (e) {
      dev.log('Error sending message: $e');
      if (mounted) {
        showErrorSnackbar('فشل في إرسال الرسالة', context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Messages List
            Expanded(
              child: isLoading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMessagesList(),
            ),

            // Message Input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF4DB6AC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'غرفة المحادثة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد رسائل بعد',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'كن أول من يبدأ المحادثة!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Reverse messages to show oldest first (bottom to top)
    final reversedMessages = messages.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: reversedMessages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(reversedMessages[index]);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final roleColor = message.senderRole.color;
    // Check if this message is from the current user by comparing sender ID
    final isCurrentUser = message.senderId != null &&
        currentUserId != null &&
        message.senderId == currentUserId;

    // Debug logging
    dev.log(
        'Message: "${message.message.substring(0, message.message.length > 20 ? 20 : message.message.length)}"');
    dev.log('  senderId: ${message.senderId}, currentUserId: $currentUserId');
    dev.log('  isCurrentUser: $isCurrentUser');
    dev.log('  senderName: ${message.senderName}, userName: $userName');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left lane - Other users' messages
          if (!isCurrentUser)
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender info and time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message.senderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                message.senderRole.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.getFormattedTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Message bubble - Left side styling
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        message.message,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Right lane - Current user's messages
          if (isCurrentUser)
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Sender info and time
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.getFormattedTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF4DB6AC).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4DB6AC)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message.senderRole.displayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4DB6AC),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'أنت',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Message bubble - Right side styling
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4DB6AC).withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(4),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(
                          color: const Color(0xFF4DB6AC).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        message.message,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // Send button
          ElevatedButton(
            onPressed: isSending ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    children: [
                      Icon(Icons.send, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'إرسال',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          // Message input field
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF4DB6AC),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
