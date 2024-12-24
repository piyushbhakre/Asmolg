import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Provider/UserController.dart';

class ChatScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const ChatScreen({Key? key, required this.subjectId, required this.subjectName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserController userController = Get.find<UserController>();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  final Set<int> _selectedMessages = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentUserDetails();
  }

  void fetchCurrentUserDetails() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email != null) {
      userController.fetchUserDetailsFromFirestore(currentUser.email!);
    } else {
      userController.fullName.value = 'No full name';
    }
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      setState(() => _isSending = true); // Show loading spinner
      final String messageText = _controller.text.trim();
      final String userName = userController.fullName.value.isEmpty
          ? 'Anonymous'
          : userController.fullName.value;
      final String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Email';
      final DateTime now = DateTime.now();

      final int timestampInMillis = now.millisecondsSinceEpoch;
      final String formattedTime = _formatTime(now);
      final String formattedDate = _formatDateToStore(now); // Store in DD-MM-YYYY format

      try {
        final DocumentReference chatDoc = FirebaseFirestore.instance
            .collection('CHAT_GROUP')
            .doc(widget.subjectId);

        final message = {
          'sender': userName,
          'email': userEmail,
          'message': messageText,
          'timestamp': timestampInMillis,
          'time': formattedTime,
          'date': formattedDate,
        };

        await chatDoc.update({
          'messages': FieldValue.arrayUnion([message]),
        });

        _controller.clear();
        _scrollToBottom();
      } catch (e) {
        print("Error sending message: $e");
      } finally {
        setState(() => _isSending = false); // Hide loading spinner
      }
    }
  }

  String _formatDateToStore(DateTime timestamp) =>
      "${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}";

  String _formatDateDivider(String date) {
    final parts = date.split('-'); // Split DD-MM-YYYY
    final day = parts[0];
    final month = int.parse(parts[1]);

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return "$day ${months[month - 1]}"; // Convert to DD-MMM
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _toggleSelection(int index, String messageEmail) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    if (messageEmail == currentUserEmail) {
      setState(() {
        if (_selectedMessages.contains(index)) {
          _selectedMessages.remove(index);
        } else {
          _selectedMessages.add(index);
        }
        _isSelectionMode = _selectedMessages.isNotEmpty;
      });
    }
  }

  Future<void> _deleteSelectedMessages(List<dynamic> messages) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Messages"),
        content: const Text("Are you sure you want to delete the selected messages?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Yes")),
        ],
      ),
    );

    if (confirm) {
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

      try {
        // Fetch the document data
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('CHAT_GROUP')
            .doc(widget.subjectId)
            .get();

        List<dynamic> allMessages = documentSnapshot['messages'] ?? [];

        // Create a list of messages to delete
        List<dynamic> messagesToDelete = [];
        for (int selectedIndex in _selectedMessages) {
          final selectedMessage = allMessages[selectedIndex];

          // Only add messages that belong to the current user
          if (selectedMessage['email'] == currentUserEmail) {
            messagesToDelete.add(selectedMessage);
          }
        }

        // Create a new list excluding the messages to delete
        List<dynamic> updatedMessages = allMessages.where((message) {
          return !messagesToDelete.contains(message);
        }).toList();

        // Update Firestore with the filtered messages
        await FirebaseFirestore.instance
            .collection('CHAT_GROUP')
            .doc(widget.subjectId)
            .update({'messages': updatedMessages});

        // Reset selection mode
        setState(() {
          _selectedMessages.clear();
          _isSelectionMode = false;
        });

        Fluttertoast.showToast(
          msg: "Selected messages deleted successfully.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM, // Position of the toast
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Failed to delete the selected messages: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM, // Position of the toast
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
    }
  }

  String _formatTime(DateTime timestamp) =>
      "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white38,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(color: Colors.black, fontSize: 18),
            ),
            Obx(() {
              return Text(
                '${userController.fullName.value}',
                style: const TextStyle(color: Colors.black, fontSize: 14),
              );
            }),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: _isSelectionMode
            ? [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteSelectedMessages([]),
          ),
        ]
            : [],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.amber.shade100,
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              "⚠️ All messages will be deleted every Friday midnight!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('CHAT_GROUP')
                  .doc(widget.subjectId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final messages = List.from(data['messages'] ?? []);

                messages.sort((a, b) =>
                    (a['timestamp'] as int).compareTo(b['timestamp'] as int));

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isCurrentUser = message['email'] ==
                        FirebaseAuth.instance.currentUser?.email;

                    // Show date divider if the current message's date is different from the previous one
                    final showDateDivider = index == 0 ||
                        messages[index]['date'] != messages[index - 1]['date'];
                    final formattedDateDivider =
                    _formatDateDivider(message['date']); // Convert to DD-MMM

                    return Column(
                      children: [
                        if (showDateDivider)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  formattedDateDivider,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onLongPress: () => _toggleSelection(index, message['email']),
                          onTap: _isSelectionMode ? () => _toggleSelection(index, message['email']) : null,
                          child: Align(
                            alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isCurrentUser ? Colors.lightBlue.shade100 : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(8),
                                  topRight: const Radius.circular(8),
                                  bottomLeft: isCurrentUser ? const Radius.circular(8) : const Radius.circular(0),
                                  bottomRight: isCurrentUser ? const Radius.circular(0) : const Radius.circular(8),
                                ),
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                              ),
                              child: IntrinsicWidth(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75, // Max 75% of screen width
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Row with Sender Name and Tick/Circle
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          if (_isSelectionMode && isCurrentUser)
                                            Container(
                                              width: 16, // Small size for the circle
                                              height: 16,
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _selectedMessages.contains(index)
                                                    ? Colors.green // Show green circle for selected messages
                                                    : Colors.transparent, // Transparent for unselected messages
                                                border: Border.all(
                                                  color: _selectedMessages.contains(index)
                                                      ? Colors.green // Green border for selected messages
                                                      : Colors.grey, // Grey border for unselected messages
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: _selectedMessages.contains(index)
                                                  ? const Icon(Icons.check, color: Colors.white, size: 10) // Green tick for selected
                                                  : null, // No content for unselected
                                            ),
                                          Expanded(
                                            child: Text(
                                              isCurrentUser ? "You" : message['sender'], // "You" for current user, sender name for others
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 1), // Space between sender name and message text
                                      // Message Text
                                      Text(
                                        message['message'],
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Timestamp
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          message['time'],
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // White background for the text field
                      borderRadius: BorderRadius.circular(0), // Rounded edges
                      border: Border.all(color: Colors.grey.shade300, width: 1), // Light grey border
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8), // Left padding inside the input box
                        Expanded(
                          child: TextField(
                            focusNode: _focusNode,
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...', // Match the hint text
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Space between input box and send button
                CircleAvatar(
                  radius: 24, // Circular button
                  backgroundColor: Colors.black, // Match the grey send button background
                  child: _isSending
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4,
                  )
                      : IconButton(
                    icon: const Icon(Icons.send, color: Colors.white), // Grey send icon
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20)
        ],
      ),
    );
  }
}
