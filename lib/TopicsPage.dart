import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'NotesPage.dart';

class TopicsPage extends StatefulWidget {
  final String subjectName;
  final String subjectId;
  final String departmentName;

  const TopicsPage({
    Key? key,
    required this.subjectName,
    required this.subjectId,
    required this.departmentName,
  }) : super(key: key);

  @override
  _TopicsPageState createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  String _searchTerm = ''; // Holds the search term entered by the user
  final TextEditingController _searchController = TextEditingController();

  // Fetch department subjects
  Future<QuerySnapshot> getDepartmentSubjects() {
    return FirebaseFirestore.instance
        .collection('notes')
        .where('department', isEqualTo: widget.departmentName)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.subjectName}'),
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
                hintText: 'Search Topics...',
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
            // Topics FutureBuilder
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: getDepartmentSubjects(),
                builder: (context, departmentSnapshot) {
                  if (departmentSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (departmentSnapshot.hasError) {
                    return Center(child: Text('Error: ${departmentSnapshot.error}'));
                  }

                  if (departmentSnapshot.hasData && departmentSnapshot.data != null) {
                    var departmentDocs = departmentSnapshot.data!.docs;

                    if (departmentDocs.isEmpty) {
                      return const Center(child: Text('Department not found.'));
                    }

                    var departmentDoc = departmentDocs.first;

                    Future<QuerySnapshot> getSubjectTopics() {
                      return FirebaseFirestore.instance
                          .collection('notes')
                          .doc(departmentDoc.id) // Department document ID
                          .collection('subjects')
                          .where('subject', isEqualTo: widget.subjectName)
                          .get();
                    }

                    return FutureBuilder<QuerySnapshot>(
                      future: getSubjectTopics(),
                      builder: (context, subjectSnapshot) {
                        if (subjectSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (subjectSnapshot.hasError) {
                          return Center(child: Text('Error: ${subjectSnapshot.error}'));
                        }

                        if (subjectSnapshot.hasData && subjectSnapshot.data != null) {
                          var subjectDocs = subjectSnapshot.data!.docs;

                          if (subjectDocs.isEmpty) {
                            return const Center(child: Text('Subject not found.'));
                          }

                          var subjectDoc = subjectDocs.first;

                          CollectionReference topicsRef = FirebaseFirestore.instance
                              .collection('notes')
                              .doc(departmentDoc.id)
                              .collection('subjects')
                              .doc(subjectDoc.id)
                              .collection('topics'); // Topics subcollection

                          return FutureBuilder<QuerySnapshot>(
                            future: topicsRef.get(),
                            builder: (context, topicsSnapshot) {
                              if (topicsSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (topicsSnapshot.hasError) {
                                return Center(child: Text('Error: ${topicsSnapshot.error}'));
                              }

                              if (topicsSnapshot.hasData && topicsSnapshot.data != null) {
                                final topics = topicsSnapshot.data!.docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return data['topic'] ?? 'Unknown Topic'; // Fetch the topic field
                                }).where((topic) {
                                  // Filter topics based on the search term
                                  return topic.toLowerCase().contains(_searchTerm);
                                }).toList();

                                if (topics.isEmpty) {
                                  return const Center(child: Text('No topics found for this subject.'));
                                }

                                return ListView.builder(
                                  itemCount: topics.length,
                                  itemBuilder: (context, index) {
                                    final topic = topics[index];
                                    return ModernTopicCard(
                                      topicName: topic,
                                      departmentDocId: departmentDoc.id,  // Pass departmentDocId
                                      subjectDocId: subjectDoc.id,        // Pass subjectDocId
                                    );
                                  },
                                );
                              }

                              return const Center(child: Text('No topics found.'));
                            },
                          );
                        }

                        return const Center(child: Text('No subjects found.'));
                      },
                    );
                  }

                  return const Center(child: Text('Department not found.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernTopicCard extends StatelessWidget {
  final String topicName;
  final String departmentDocId; // Add departmentDocId
  final String subjectDocId;    // Add subjectDocId

  const ModernTopicCard({
    Key? key,
    required this.topicName,
    required this.departmentDocId, // Add this
    required this.subjectDocId,    // Add this
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotesPage(
              topicName: topicName,
              departmentDocId: departmentDocId, // Pass departmentDocId
              subjectDocId: subjectDocId,       // Pass subjectDocId
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0), // Space between cards
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white, // No gradient, just a solid background
          borderRadius: BorderRadius.circular(12), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 3), // Shadow for depth effect
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: Topic Name
            Text(
              topicName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Second row: Topic Icon
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.bookOpen,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "View Notes",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
