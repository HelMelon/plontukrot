import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

class PlaceholderWithIcon extends StatelessWidget {
  const PlaceholderWithIcon({super.key});

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
        Center(
          child: Icon(
            Icons.add_a_photo,
            color: context.colors.onPrimary,
            size: context.dimensions.photoPlaceholder,
          ),
        ),
      ],
    );
  }
}
