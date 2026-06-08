import 'package:flutter/material.dart';

class PlantFrameClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final left = size.width * 0.1116;
    final right = size.width * 0.1116;
    final top = size.height * 0.122;
    final bottom = size.height * 0.138;

    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, size.width - right, size.height - bottom),
        const Radius.circular(16),
      ),
    );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
