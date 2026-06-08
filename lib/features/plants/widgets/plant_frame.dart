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
      // 🛡️ РЕШЕНИЕ: Align сбрасывает принудительное растяжение от родительских виджетов
      child: Align(
        alignment: Alignment.centerLeft, // Выравниваем рамку по левому краю
        child: AspectRatio(
          aspectRatio: 470 / 836,
          child: Stack(
            fit: StackFit.expand,
            children: [
              /// 🌿 IMAGE (ВАЖНО: COVER)
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

              /// 🖼 FRAME (ТОЛЬКО OVERLAY)
              Positioned.fill(
                child: Image.asset('assets/images/frame.png', fit: BoxFit.fill),
              ),

              /// 🌿 TEXT (ПРОПОРЦИОНАЛЬНОЕ ПОЗИЦИОНИРОВАНИЕ)
              Positioned.fill(
                child: FractionallySizedBox(
                  widthFactor:
                      0.7, // ↔️ Текст занимает 70% ширины рамки (не залезет на боковые узоры)
                  heightFactor:
                      0.08, // ↕️ Текст занимает ровно 8% от общей высоты рамки
                  alignment: const Alignment(
                    0.0,
                    0.82,
                  ), // 🎯 Точное смещение: 0.0 по центру, 0.82 — внизу на плашке
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
