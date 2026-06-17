import 'package:flutter/material.dart';

class PlaceholderWithIcon extends StatelessWidget {
  const PlaceholderWithIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.6,
          child: Image.asset(
            'assets/images/default-img.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        const Center(
          child: Icon(Icons.add_a_photo, color: Colors.white, size: 40.0),
        ),
      ],
    );
  }
}
