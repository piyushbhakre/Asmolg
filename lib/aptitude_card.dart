import 'package:flutter/material.dart';
import 'package:magic_text/magic_text.dart';
import 'AptitudeTopicPage.dart';

class AptitudeCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String description;

  const AptitudeCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.description,
  }) : super(key: key);

  @override
  _AptitudeCardState createState() => _AptitudeCardState();
}

class _AptitudeCardState extends State<AptitudeCard> {
  bool _isSubscribed = true; // Treat all cards as subscribed by default

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate directly to the topic page as everything is free
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AptitudeTopicPage(
              aptitudeName: widget.title,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Colors.grey.shade300, // Outline color
            width: 1.5, // Outline width
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with rounded corners at the top
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
              child: Image.asset(
                widget.imageUrl,
                height: 110,
                width: double.infinity,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MagicText(
                    widget.title,
                    breakWordCharacter: '-', // Adjust word breaks if necessary
                    smartSizeMode: true, // Enables responsive resizing based on screen size
                    minFontSize: 11, // Set minimum font size
                    maxFontSize: 15, // Set maximum font size
                    textStyle: TextStyle(
                      fontSize: 14, // Base font size that will adjust responsively
                      color: Colors.black87, // Text color
                      fontWeight: FontWeight.w600, // Font weight
                    ), asyncMode: true,
                  ),
                  const Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
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
