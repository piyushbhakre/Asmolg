import 'package:asmolg/Constant/ApiConstant.dart';
import 'package:asmolg/Pdf_Viewer/OthefWidgets/Beta_lable.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SummaryPage extends StatefulWidget {
  final String summaryText;

  const SummaryPage({Key? key, required this.summaryText}) : super(key: key);

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final TextEditingController _messageController = TextEditingController();
  final SmartReply _smartReply = SmartReply();
  final List<Map<String, dynamic>> _chatMessages = [];
  late GenerativeModel _geminiModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: GEMINI_API_KEY,
    );

    // Add the summary as the first bot message
    _chatMessages.add({
      'message': widget.summaryText,
      'isBot': true,
    });
  }

  @override
  void dispose() {
    _smartReply.close();
    super.dispose();
  }

  /// Splits the summary text and returns a list of TextSpans
  List<TextSpan> _parseSummary(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*'); // Matches text between '**'
    int lastIndex = 0;

    // Find and process all bold matches
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1), // Add bold text
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
    }

    // Add remaining normal text after the last match
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'message': text, 'isBot': false});
      _isLoading = true;
    });

    // Add the user's message to the conversation for Smart Reply context
    _smartReply.addMessageToConversationFromLocalUser(text, DateTime.now().millisecondsSinceEpoch);

    // Use Gemini API for summary-based questions
    final botReply = await _fetchGeminiResponse(text);

    setState(() {
      if (botReply.isNotEmpty) {
        _chatMessages.add({'message': botReply, 'isBot': true});
      } else {
        _chatMessages.add({'message': "I'm not sure how to answer that.", 'isBot': true});
      }
      _isLoading = false;
    });

    _messageController.clear();
  }

  Future<String> _fetchGeminiResponse(String query) async {
    try {
      final content = [
        Content.text("Summary: ${widget.summaryText}\nUser Question: $query"),
      ];
      final response = await _geminiModel.generateContent(content);

      return response.text ?? "No response available from Gemini.";
    } catch (e) {
      debugPrint("Error using Gemini API: $e");
      return "Sorry, I couldn't process your question.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Text("ChatBot"),
            SizedBox(width: 8),
            BetaLabel(),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatMessages[_chatMessages.length - 1 - index];
                  final isBot = message['isBot'] as bool;

                  return Align(
                    alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isBot ? Colors.grey[300] : Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isBot
                          ? RichText(
                        text: TextSpan(
                          children: _parseSummary(message['message']),
                          style: const TextStyle(color: Colors.black),
                        ),
                      )
                          : Text(
                        message['message'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type your question...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () => _sendMessage(_messageController.text),
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
