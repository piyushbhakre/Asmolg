import 'package:flutter/material.dart';


class CourseCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String price;
  final String description;

  const CourseCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // // // Navigate to the CourseBuyPage
        // // Navigator.push(
        // //   context,
        // //   MaterialPageRoute(
        // //     builder: (context) => CourseBuyPage(
        // //       title: name,
        // //       imageUrl: imageUrl,
        // //       description: description,
        // //       price: price,
        // //     ),
        // //   ),
        // );
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,

                      color: Colors.black87, // Title color
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: $price',
                    style: TextStyle(
                      fontSize: 12,
                      color: price == 'Free' ? Colors.green : Colors.blueGrey,
                      fontWeight: FontWeight.w500, // Slightly lighter weight
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
