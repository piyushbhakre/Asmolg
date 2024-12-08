import 'package:flutter/material.dart';
import 'department_card.dart'; // Import DepartmentCard
import 'programming_course_card.dart'; // Import ProgrammingCourseCard
import 'aptitude_card.dart'; // Import AptitudeCard

class SeeAllPage extends StatefulWidget {
  final String title;
  final List<dynamic> items; // Accept any widget type

  const SeeAllPage({Key? key, required this.title, required this.items}) : super(key: key);

  @override
  _SeeAllPageState createState() => _SeeAllPageState();
}

class _SeeAllPageState extends State<SeeAllPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Filter items based on the search query
    List<dynamic> filteredItems = widget.items.where((item) {
      if (item is DepartmentCard) {
        // Assuming DepartmentCard has a departmentName property
        return item.departmentName.toLowerCase().contains(searchQuery.toLowerCase());
      } else if (item is  CourseCard) {
        // Assuming ProgrammingCourseCard has a name property
        return item.name.toLowerCase().contains(searchQuery.toLowerCase());
      } else if (item is AptitudeCard) {
        // Assuming AptitudeCard has a title property
        return item.title.toLowerCase().contains(searchQuery.toLowerCase());
      }
      return false; // Exclude items that do not match any of the types
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query; // Update the search query
                });
              },
            ),

            const SizedBox(height: 16.0), // Add some spacing

            // Grid view for filtered items
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 items per row
                  crossAxisSpacing: 8.0, // Spacing between columns
                  mainAxisSpacing: 12.0, // Spacing between rows
                  childAspectRatio: 0.8, // Aspect ratio of each item (width/height)
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  return filteredItems[index]; // Return the item for each grid cell
                },
              ),
            ),
            const SizedBox(height: 20.0), // Add some spacing
          ],
        ),
      ),
    );
  }
}
