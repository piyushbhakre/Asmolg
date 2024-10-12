import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'fileViewer.dart';

class NotesPage extends StatefulWidget {
  final String topicName;
  final String departmentDocId; // ID of the department document
  final String subjectDocId;    // ID of the subject document

  const NotesPage({
    Key? key,
    required this.topicName,
    required this.departmentDocId,
    required this.subjectDocId,
  }) : super(key: key);

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _searchTerm = ''; // Holds the search term entered by the user
  final TextEditingController _searchController = TextEditingController();

  // Function to fetch notes from Firestore under the content subcollection
  Future<QuerySnapshot> fetchNotes() {
    return FirebaseFirestore.instance
        .collection('notes')
        .doc(widget.departmentDocId) // Department document ID
        .collection('subjects')
        .doc(widget.subjectDocId) // Subject document ID
        .collection('topics')
        .where('topic', isEqualTo: widget.topicName) // Filter by topic name
        .get()
        .then((topicSnapshot) {
      if (topicSnapshot.docs.isNotEmpty) {
        String topicDocId = topicSnapshot.docs.first.id;
        return FirebaseFirestore.instance
            .collection('notes')
            .doc(widget.departmentDocId)
            .collection('subjects')
            .doc(widget.subjectDocId)
            .collection('topics')
            .doc(topicDocId)
            .collection('content') // Content subcollection
            .get();
      } else {
        throw Exception('No content found for the selected topic.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.topicName}'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search Notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value.toLowerCase(); // Update search term
                });
              },
            ),
            const SizedBox(height: 16),

            // FutureBuilder to fetch notes
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: fetchNotes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    final notesData = snapshot.data!.docs;

                    if (notesData.isEmpty) {
                      return const Center(child: Text('No notes found for this topic.'));
                    }

                    final filteredNotes = notesData.where((doc) {
                      final note = doc.data() as Map<String, dynamic>;
                      final noteName = note['content']?.toLowerCase() ?? 'unknown';
                      return noteName.contains(_searchTerm); // Filter based on search term
                    }).toList();

                    if (filteredNotes.isEmpty) {
                      return const Center(child: Text('No notes found matching your search.'));
                    }

                    return ListView.builder(
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index].data() as Map<String, dynamic>;
                        return ModernNoteCard(
                          noteName: note['content'] ?? 'Unknown',
                          uploadedDate: note['uploadedDate'] ?? 'Unknown Date',
                          fileUrl: note['fileURL'] ?? '#',
                          fileType: note['type'] ?? 'pdf', // Default to 'pdf' if type is missing
                        );
                      },
                    );
                  }

                  return const Center(child: Text('No notes found.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernNoteCard extends StatelessWidget {
  final String noteName;
  final dynamic uploadedDate; // Change to dynamic to handle both String and Timestamp
  final String fileUrl;  // URL to the file
  final String fileType; // 'pdf', 'ppt', or 'word'

  const ModernNoteCard({
    Key? key,
    required this.noteName,
    required this.uploadedDate,
    required this.fileUrl,
    required this.fileType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert Timestamp to DateTime, then format to a readable string
    String formattedDate;
    if (uploadedDate is Timestamp) {
      DateTime date = uploadedDate.toDate(); // Convert Timestamp to DateTime
      formattedDate = "${date.day}/${date.month}/${date.year}"; // Format the date
    } else {
      formattedDate = uploadedDate.toString(); // If it's already a string, use it directly
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileViewerPage(fileUrl: fileUrl),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0), // Space between cards
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 3), // Shadow for depth effect
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left-aligned, larger file icon (PDF, PPT, Word)
              FaIcon(
                fileType == 'pdf'
                    ? FontAwesomeIcons.filePdf
                    : fileType == 'ppt'
                    ? FontAwesomeIcons.filePowerpoint
                    : FontAwesomeIcons.fileWord, // File type icon
                color: fileType == 'pdf'
                    ? Colors.blue
                    : fileType == 'ppt'
                    ? Colors.blue
                    : Colors.blue,
                size: 25, // Larger icon
              ),
              const SizedBox(width: 16), // Space between icon and text

              // Text column: Note name and uploaded date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noteName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8), // Space between name and date
                    Text(
                      "Uploaded: $formattedDate", // Uploaded date
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
