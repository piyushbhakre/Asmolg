import 'package:asmolg/MainScreeens/ChatScreen.dart';
import 'package:asmolg/Provider/offline-online_status.dart';
import 'package:asmolg/subject.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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

  bool _isLoading = false; // Track loading state

  // Fetch Notes
  Future<List<Map<String, dynamic>>> fetchNotes() async {
    try {
      // Fetch department document
      QuerySnapshot departmentSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('department', isEqualTo: widget.departmentDocId)
          .get();

      if (departmentSnapshot.docs.isNotEmpty) {
        final departmentDocId = departmentSnapshot.docs.first.id;

        // Fetch subjects and content
        QuerySnapshot contentSnapshot = await FirebaseFirestore.instance
            .collection('notes')
            .doc(departmentDocId)
            .collection('subjects')
            .doc(widget.subjectDocId)
            .collection('content')
            .get();

        return contentSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception('No department found matching the provided departmentDocId.');
      }
    } catch (e) {
      throw Exception('Error fetching notes: $e');
    }
  }

  // Floating button click - Loading effect with motivational text
  Future<void> _handleFloatingButtonClick() async {
    setState(() {
      _isLoading = true; // Show loading screen
    });

    final chatGroupRef = FirebaseFirestore.instance.collection('CHAT_GROUP');

    try {
      final snapshot = await chatGroupRef.doc(widget.subjectDocId).get();

      if (!snapshot.exists) {
        // Create a new document if it doesn't exist
        await chatGroupRef.doc(widget.subjectDocId).set({
          'subjectName': widget.subjectName,
          'createdAt': FieldValue.serverTimestamp(),
          'messages': [], // Initialize with an empty array
        });
      }

      // Redirect to ChatScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
              subjectId: widget.subjectDocId, subjectName: widget.subjectName),
        ),
      );
    } catch (error) {
      CherryToast.error(
        title: const Text("Error"),
        description: Text("Failed to load chat group. Please try again."),
      ).show(context);
    } finally {
      setState(() {
        _isLoading = false; // Hide loading screen
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the navigation bar height dynamically
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        bottom: OfflineBanner(),
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
            Get.back();
          },
        ),
      ),
      body: SafeArea(
        bottom: false, // Allow manual handling of bottom padding
        child: Stack(
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

                  // Notes list
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchNotes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // Shimmer Effect
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.white,
                            child: ListView.builder(
                              itemCount: 8,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.hasData) {
                          final notesData = snapshot.data!;
                          final filteredNotes = notesData.where((note) {
                            final noteName =
                                note['content']?.toString().toLowerCase() ?? '';
                            return noteName.contains(_searchTerm);
                          }).toList();

                          if (filteredNotes.isEmpty) {
                            return const Center(
                                child: Text('No notes found matching your search.'));
                          }

                          return ListView.builder(
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              final note = filteredNotes[index];
                              return ModernNoteCard(
                                noteName: note['content'] ?? 'Unknown',
                                uploadedDate: note['uploadedDate'] ?? 'Unknown Date',
                                fileUrl: note['fileURL'] ?? '#',
                                fileType: note['type'] ?? 'pdf',
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

            // Floating Action Button - Adjusted for Navigation Bar
            Positioned(
              bottom: bottomPadding + 50, // Adjust based on navigation bar height
              right: 30,
              child: FloatingActionButton(
                onPressed: _handleFloatingButtonClick,
                backgroundColor: Colors.black,
                child: const Icon(Icons.chat, color: Colors.white),
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6), // Blur background
                  child: Center(
                    child: Card(
                      color: Colors.white, // Completely white card view
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),

                            // Loading Animation - Staggered Dots Wave
                            LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.black, // Customize color
                              size: 50,           // Customize size
                            ),

                            const SizedBox(height: 16),

                            // Motivational Text
                            const Text(
                              "Get ready to join your group chat!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              "We’re preparing everything for you...",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
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
