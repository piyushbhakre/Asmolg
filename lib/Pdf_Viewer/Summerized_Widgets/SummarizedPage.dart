import 'package:flutter/material.dart';

class SummaryPage extends StatelessWidget {
  final String summaryText;

  const SummaryPage({Key? key, required this.summaryText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            summaryText,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}