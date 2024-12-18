import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  Future<void> _deleteSelectedMessages(List messages) async {
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

        // Create a new list excluding the selected messages
        List<dynamic> updatedMessages = allMessages.where((message) {
          final bool isSelected = _selectedMessages.contains(allMessages.indexOf(message));
          final bool isOwnedByUser = message['email'] == currentUserEmail;

          // Only exclude messages that are both selected and owned by the user
          return !(isSelected && isOwnedByUser);
        }).toList();

        // Update Firestore with the filtered list
        await FirebaseFirestore.instance
            .collection('CHAT_GROUP')
            .doc(widget.subjectId)
            .update({'messages': updatedMessages});

        // Reset selection mode
        setState(() {
          _selectedMessages.clear();
          _isSelectionMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selected messages deleted successfully.",
              style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green),
        );
      } catch (e) {
        print("Error deleting messages: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete the selected messages.",
          style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  String _formatTime(DateTime timestamp) =>
      "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: Colors.blueAccent,
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
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('CHAT_GROUP')
                  .doc(widget.subjectId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final messages = List.from(data['messages'] ?? []);

                messages.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

                String? lastDate;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isSelected = _selectedMessages.contains(index);
                    final bool isCurrentUser = message['email'] == FirebaseAuth.instance.currentUser?.email;

                    // Show date divider if the current message's date is different from the previous one
                    final showDateDivider = index == 0 || messages[index]['date'] != messages[index - 1]['date'];
                    final formattedDateDivider = _formatDateDivider(message['date']); // Convert to DD-MMM

                    return Column(
                      children: [
                        if (showDateDivider)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
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
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCurrentUser ? Colors.green : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: Colors.blueAccent, width: 2)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    message['message'],
                                    style: TextStyle(
                                      color: isCurrentUser ? Colors.white : Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message['time'],
                                    style: TextStyle(
                                      color: isCurrentUser ? Colors.white70 : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                _isSending
                    ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                )
                    : IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
