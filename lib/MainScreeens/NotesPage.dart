import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../fileViewer.dart';

class NotesPage extends StatefulWidget {
  final String departmentDocId; // ID of the department document
  final String subjectDocId;    // ID of the subject document
  final String subjectName;    // Subject name

  const NotesPage({
    Key? key,
    required this.departmentDocId,
    required this.subjectDocId,
    required this.subjectName,
  }) : super(key: key);

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  String _searchTerm = ''; // Holds the search term entered by the user
  final TextEditingController _searchController = TextEditingController();

  // Function to fetch notes from Firestore under the 'content' sub-collection
  Future<QuerySnapshot> fetchNotes() {
    // Query the 'notes' collection where 'department' field matches the departmentDocId
    return FirebaseFirestore.instance
        .collection('notes')
        .where('department', isEqualTo: widget.departmentDocId) // Match the department field
        .get()
        .then((QuerySnapshot notesSnapshot) async {
      if (notesSnapshot.docs.isNotEmpty) {
        // Assume there's only one matching document in 'notes' collection for this department
        final departmentDocId = notesSnapshot.docs.first.id;

        // Now query the subjects sub-collection under the matching document
        return FirebaseFirestore.instance
            .collection('notes')
            .doc(departmentDocId) // The matched department document
            .collection('subjects')
            .doc(widget.subjectDocId) // Subject document ID
            .collection('content') // Content sub-collection
            .get();
      } else {
        throw Exception('No department found matching the provided departmentDocId.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.subjectName),
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

                    // Filter notes based on search term
                    final filteredNotes = notesData.where((doc) {
                      final noteData = doc.data() as Map<String, dynamic>;
                      final noteName = noteData['content']?.toLowerCase() ?? 'unknown';
                      return noteName.contains(_searchTerm);
                    }).toList();

                    if (filteredNotes.isEmpty) {
                      return const Center(child: Text('No notes found matching your search.'));
                    }

                    return ListView.builder(
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index].data() as Map<String, dynamic>;

                        // Ensure required fields exist
                        final noteName = note['content'] ?? 'Unknown';
                        final uploadedDate = note['uploadedDate'] ?? 'Unknown Date';
                        final fileUrl = note['fileURL'] ?? '#';
                        final fileType = note['type'] ?? 'pdf'; // Default to 'pdf'

                        return ModernNoteCard(
                          noteName: noteName,
                          uploadedDate: uploadedDate,
                          fileUrl: fileUrl,
                          fileType: fileType,
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

// ModernNoteCard widget for displaying individual notes
class ModernNoteCard extends StatelessWidget {
  final String noteName;
  final dynamic uploadedDate; // Can be either String or Timestamp
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
      formattedDate = uploadedDate.toString(); // If it's a string, use it directly
    }

    return GestureDetector(
      onTap: () {
        if (fileUrl != '#' && fileUrl.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileViewerPage(fileUrl: fileUrl),
            ),
          );
        } else {
          // Show a message if file URL is not available
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File URL not available')),
          );
        }
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
                    ? Colors.red
                    : fileType == 'ppt'
                    ? Colors.orange
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
