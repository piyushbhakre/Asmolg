import 'package:flutter/material.dart';
import 'subject.dart';

class DepartmentCard extends StatelessWidget {
  final String imageUrl;
  final String departmentName;

  const DepartmentCard({
    Key? key,
    required this.imageUrl,
    required this.departmentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to SubjectPage when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectPage(departmentName: departmentName),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black26, // Shadow color
              blurRadius: 4.0, // Shadow blur radius
              offset: Offset(1, 1), // Shadow offset
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with rounded corners at the top
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
              child: Image.network(
                imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                departmentName,
                textAlign: TextAlign.center, // Center align the text
                style: const TextStyle(
                  fontSize: 14, // Keep or adjust the font size as needed
                  color: Colors.black87, // Title color for better contrast
                  fontWeight: FontWeight.bold, // Make the font bolder
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
