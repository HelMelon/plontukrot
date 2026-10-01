import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:plontukrot/features/plants/widgets/common/pick_and_crop_plant_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizeImageBytesForCrop emits a JPEG the cropper can parse', () async {
    final source = img.Image(width: 40, height: 20);
    img.fill(source, color: img.ColorRgb8(200, 10, 10));
    final png = Uint8List.fromList(img.encodePng(source));

    final normalized = await normalizeImageBytesForCrop(png);
    expect(normalized, isNotNull);
    expect(normalized!.length, greaterThan(2));
    expect(normalized[0], 0xFF);
    expect(normalized[1], 0xD8);

    final decoded = img.decodeJpg(normalized);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(1280));
    expect(decoded.height, greaterThan(0));

    final parsed = defaultImageParser(normalized);
    expect(parsed.width, decoded.width);
    expect(parsed.height, decoded.height);
  });

  test('flutter picture bytes round-trip through normalize', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 40, 20),
      ui.Paint()..color = const ui.Color(0xFFFF0000),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(40, 20);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final bytes = byteData!.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    final normalized = await normalizeImageBytesForCrop(bytes);
    expect(normalized, isNotNull);
    expect(img.decodeJpg(normalized!), isNotNull);
  });
}
