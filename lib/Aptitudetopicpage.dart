import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'fileViewer.dart'; // PDF Viewer

class AptitudeTopicPage extends StatefulWidget {
  final String aptitudeName;

  const AptitudeTopicPage({
    Key? key,
    required this.aptitudeName,
  }) : super(key: key);

  @override
  _AptitudeTopicPageState createState() => _AptitudeTopicPageState();
}

class _AptitudeTopicPageState extends State<AptitudeTopicPage> {
  String _searchTerm = ''; // Holds the search term entered by the user
  final TextEditingController _searchController = TextEditingController();

  // Fetch aptitude topics along with file URLs
  Future<QuerySnapshot> getAptitudeTopics() {
    return FirebaseFirestore.instance
        .collection('aptitude')
        .where('course_name', isEqualTo: widget.aptitudeName)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.reference.collection('topics').get();
      }
      return Future.value(null); // Return null if no documents found
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.aptitudeName} Topics'),
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
            future: getAptitudeTopics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerList(); // Display shimmer while loading
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.hasData && snapshot.data != null) {
                var topicsDocs = snapshot.data!.docs;

                if (topicsDocs.isEmpty) {
                  return const Center(child: Text('No topics found.'));
                }

                // Fetch topic_name, fileUrl, and formatted uploadedDate for each topic
                final topics = topicsDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Format ISO string to `dd-MM-yyyy`
                  String formattedDate = '';
                  if (data['uploadedDate'] != null && data['uploadedDate'] is String) {
                    DateTime dateTime = DateTime.parse(data['uploadedDate']);
                    formattedDate =
                    "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
                  } else {
                    formattedDate = 'Unknown Date';
                  }

                  return {
                    'topic_name': data['topic_name'] ?? 'Unknown Topic',
                    'fileUrl': data['fileUrl'] ?? '',
                    'uploadedDate': formattedDate,
                  };
                }).where((topic) {
                  // Filter topics based on the search term
                  return topic['topic_name'].toLowerCase().contains(_searchTerm);
                }).toList();

                if (topics.isEmpty) {
                  return const Center(child: Text('No topics match your search.'));
                }

                return ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return AptitudeTopicCard(
                      topicName: topic['topic_name'],
                      fileUrl: topic['fileUrl'],
                      uploadedDate: topic['uploadedDate'],
                    );
                  },
                );
              }

              return const Center(child: Text('No topics found.'));
            },
          ),
        )
          ],
        ),
      ),
    );
  }
}

// Shimmer Placeholder
Widget _buildShimmerList() {
  return ListView.builder(
    itemCount: 8, // Number of shimmer placeholders
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                // Placeholder for the left-aligned icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),

                // Placeholder for text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 15,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 150,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class AptitudeTopicCard extends StatelessWidget {
  final String topicName;
  final String fileUrl;
  final String uploadedDate; // Expect uploadedDate as String

  const AptitudeTopicCard({
    Key? key,
    required this.topicName,
    required this.fileUrl,
    required this.uploadedDate, // Date should be passed as String
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (fileUrl.isNotEmpty) {
          // Navigate to the FileViewerPage with fileUrl
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileViewerPage(fileUrl: fileUrl),
            ),
          );
        } else {
          // Handle case where no fileUrl is provided
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file available for this topic.')),
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white, // Solid background color
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left-aligned icon based on content type
                FaIcon(
                  FontAwesomeIcons.filePdf, // Icon for the topic
                  color: Colors.blue, // Use blue color for the icon
                  size: 25, // Larger size for better visibility
                ),
                const SizedBox(width: 16), // Space between icon and text

                // Topic Name Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topicName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Space between name and extra information
                      Text(
                        'Uploaded: $uploadedDate', // Display the formatted date
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
          Divider(
            height: 2,
            color: Colors.grey.shade500, // Divider line color
          ),
        ],
      ),
    );
  }
}

