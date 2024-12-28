import 'package:asmolg/MainScreeens/oneSubBillingpage.dart';
import 'package:asmolg/Provider/offline-online_status.dart';
import 'package:asmolg/fileViewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cherry_toast/cherry_toast.dart'; // CherryToast for notifications
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shimmer/shimmer.dart';
import '../Provider/CartState.dart';
import 'CartPage.dart';

class ContentPreviewPage extends StatefulWidget {
  final String departmentName;
  final String subjectName;
  final String subjectId;
  final String price;

  const ContentPreviewPage({
    Key? key,
    required this.departmentName,
    required this.subjectName,
    required this.subjectId,
    required this.price,
  }) : super(key: key);

  @override
  State<ContentPreviewPage> createState() => _ContentPreviewPageState();
}

class _ContentPreviewPageState extends State<ContentPreviewPage> {
  final User? user = FirebaseAuth.instance.currentUser; // Fetch current logged-in user
  String phone = ''; // Placeholder for phone number

  bool _isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchPDFFiles() async {
    List<Map<String, dynamic>> pdfFiles = [];
    try {
      QuerySnapshot notesSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('department', isEqualTo: widget.departmentName)
          .get();

      if (notesSnapshot.docs.isNotEmpty) {
        for (var noteDoc in notesSnapshot.docs) {
          QuerySnapshot subjectSnapshot = await FirebaseFirestore.instance
              .collection('notes')
              .doc(noteDoc.id)
              .collection('subjects')
              .get();

          for (var subjectDoc in subjectSnapshot.docs) {
            if (subjectDoc.id == widget.subjectId) {
              QuerySnapshot contentSnapshot = await FirebaseFirestore.instance
                  .collection('notes')
                  .doc(noteDoc.id)
                  .collection('subjects')
                  .doc(subjectDoc.id)
                  .collection('content')
                  .get();

              for (var contentDoc in contentSnapshot.docs) {
                pdfFiles.add({
                  'content': contentDoc['content'],
                  'fileURL': contentDoc['fileURL'],
                  'isPaid': contentDoc['isPaid'],
                });
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      CherryToast.error(
        title: const Text('Error'),
        displayIcon: true,
        description: Text('Error fetching PDFs: $e'),
        animationDuration: const Duration(milliseconds: 500),
      ).show(context);
    }
    return pdfFiles;
  }

  Future<void> fetchUserDetails() async {
    if (user != null) {
      try {
        // Fetch user details (Phone and Full Name)
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.email)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            phone = data['MobileNumber'] ?? 'No phone number';
          });
        } else {
          setState(() {
            phone = 'No phone number';
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");
        setState(() {
          phone = 'Error fetching phone number';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            bottom: OfflineBanner(),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.departmentName,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                        fontSize: 18
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.black),
                      ValueListenableBuilder<int>(
                        valueListenable: cartNotifier,
                        builder: (context, cartCount, child) {
                          return cartCount > 0
                              ? Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Text(
                              '$cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),

          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.subjectName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        child: ElevatedButton(
                          onPressed: () {
                            // Pass the current subject details, including subjectId
                            final singleSubject = [
                              {
                                'subjectName': widget.subjectName,
                                'departmentName': widget.departmentName,
                                'price': widget.price,
                                'subjectId': widget.subjectId
                              }
                            ];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OneSubBillingPage( // Corrected class name
                                  items: singleSubject,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Buy for ₹ ${widget.price}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 170,
                        child: ValueListenableBuilder<int>(
                          valueListenable: cartNotifier,
                          builder: (context, cartCount, child) {
                            final isAdded = cartNotifier.isAdded(widget.subjectId); // Check if the item is added using subjectId
                            return ElevatedButton(
                              onPressed: () {
                                if (isAdded) {
                                  // Remove item from cart if it's already added
                                  cartNotifier.removeItemById(widget.subjectId);
                                } else {
                                  // Add item to cart if it's not already added
                                  cartNotifier.addItem(
                                    widget.subjectName,
                                    widget.departmentName,
                                    widget.price,
                                    widget.subjectId,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: isAdded ? Colors.green : Colors.orange, // Set color based on whether it's added
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_cart, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAdded ? 'Added' : 'Add to Cart', // Button text changes based on cart state
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Content',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchPDFFiles(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Display shimmer effect while loading
                        return ListView.builder(
                          itemCount: 7, // Simulate 5 shimmer placeholders
                          itemBuilder: (context, index) {
                            return Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16.0),
                                width: double.infinity,
                                height: 80, // Adjust height as needed
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            );
                          },
                        );
                      }

                      if (snapshot.hasError) {
                        CherryToast.error(
                          title: const Text('Error'),
                          displayIcon: true,
                          description: const Text('Error loading PDFs'),
                          animationDuration: const Duration(milliseconds: 500),
                        ).show(context);
                        return const Center(child: Text('Error loading PDFs'));
                      }

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        // Sort the PDF files: Free (isPaid == false) content first
                        List<Map<String, dynamic>> pdfFiles = snapshot.data!;
                        pdfFiles.sort((a, b) => a['isPaid'] ? 1 : -1); // Free content (isPaid == false) comes first

                        return ListView.builder(
                          itemCount: pdfFiles.length,
                          itemBuilder: (context, index) {
                            final pdfFile = pdfFiles[index];
                            return PDFCard(
                              title: pdfFile['content'],
                              fileURL: pdfFile['fileURL'],
                              isPaid: pdfFile['isPaid'],
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text('No PDFs available'));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Loading Overlay
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.white,
                      size: 50,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PDFCard extends StatelessWidget {
  final String title;
  final String fileURL;
  final bool isPaid;

  const PDFCard({
    Key? key,
    required this.title,
    required this.fileURL,
    required this.isPaid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: isPaid
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FileViewerPage(fileUrl: fileURL),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular icon with background
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.red[100] : Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPaid ? Icons.lock : Icons.lock_open,
                    color: isPaid ? Colors.red : Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPaid ? 'Premium Access' : 'Free Access',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Open button
                Icon(
                  Icons.open_in_new,
                  color: isPaid ? Colors.grey : Colors.blue,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        // Divider
        const Divider(
          color: Colors.grey,
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }
}

