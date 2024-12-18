import 'package:asmolg/MainScreeens/ChatScreen.dart';
import 'package:asmolg/subject.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
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

  Future<QuerySnapshot> fetchNotes() {

    return FirebaseFirestore.instance
        .collection('notes')
        .where('department', isEqualTo: widget.departmentDocId)
        .get()
        .then((QuerySnapshot notesSnapshot) async {
      if (notesSnapshot.docs.isNotEmpty) {

        final departmentDocId = notesSnapshot.docs.first.id;


        return FirebaseFirestore.instance
            .collection('notes')
            .doc(departmentDocId)
            .collection('subjects')
            .doc(widget.subjectDocId)
            .collection('content')
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SubjectPage(departmentName: widget.departmentDocId),
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
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
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.white,
                          child: ListView.builder(
                            itemCount: 8, // Number of shimmer items to show
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 13.0, horizontal: 20.0),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 16,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            height: 12,
                                            width: 100,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.hasData && snapshot.data != null) {
                        final notesData = snapshot.data!.docs;

                        if (notesData.isEmpty) {
                          return const Center(
                              child: Text('No notes found for this topic.'));
                        }

                        // Filter notes based on search term
                        final filteredNotes = notesData.where((doc) {
                          final noteData = doc.data() as Map<String, dynamic>;
                          final noteName =
                              noteData['content']?.toLowerCase() ?? 'unknown';
                          return noteName.contains(_searchTerm);
                        }).toList();

                        if (filteredNotes.isEmpty) {
                          return const Center(
                              child: Text(
                                  'No notes found matching your search.'));
                        }

                        return ListView.builder(
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index].data()
                            as Map<String, dynamic>;

                            // Ensure required fields exist
                            final noteName = note['content'] ?? 'Unknown';
                            final uploadedDate =
                                note['uploadedDate'] ?? 'Unknown Date';
                            final fileUrl = note['fileURL'] ?? '#';
                            final fileType = note['type'] ??
                                'pdf'; // Default to 'pdf'

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
                )
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30, right: 30),
              child: FloatingActionButton(
                onPressed: () async {
                  final chatGroupRef =
                  FirebaseFirestore.instance.collection('CHAT_GROUP');

                  final snapshot = await chatGroupRef
                      .doc(widget.subjectDocId)
                      .get();

                  if (snapshot.exists) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                            subjectId: widget.subjectDocId,
                            subjectName: widget.subjectName),
                      ),
                    );
                  } else {
                    CherryToast.info(
                      title: Text("Coming Soon"),
                      description: Text(
                          "The chat group for this subject is not yet available."),
                    ).show(context);
                  }
                },
                backgroundColor: Colors.blue,
                child: const Icon(Icons.chat, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity, // Make the container stretch to full width
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
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
          const Divider(color: Colors.grey), // Divider between cards
        ],
      ),
    );
  }
}
