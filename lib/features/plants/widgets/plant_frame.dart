import 'package:flutter/material.dart';
import 'plant_frame_clipper.dart';
import 'package:auto_size_text/auto_size_text.dart';

class PlantFrameWidget extends StatelessWidget {
  final String imageUrl;
  final String plantName;

  const PlantFrameWidget({
    super.key,
    required this.imageUrl,
    required this.plantName,
  });

  @override
  Widget build(BuildContext context) {
    final double halfScreenHeight = MediaQuery.sizeOf(context).height / 2;

    return SizedBox(
      height: halfScreenHeight,

      child: Align(
        alignment: Alignment.centerLeft,
        child: AspectRatio(
          aspectRatio: 470 / 836,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: PlantFrameClipper(),
                child: SizedBox.expand(
                  child: imageUrl.isEmpty
                      ? Container(color: Colors.green)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                ),
              ),

              Positioned.fill(
                child: Image.asset('assets/images/frame.png', fit: BoxFit.fill),
              ),

              Positioned.fill(
                child: FractionallySizedBox(
                  widthFactor: 0.7,
                  heightFactor: 0.08,
                  alignment: const Alignment(0.0, 0.82),
                  child: Center(
                    child: AutoSizeText(
                      plantName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      minFontSize: 8,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
