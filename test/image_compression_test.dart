import 'dart:typed_data';

import 'package:campus_incident_app/services/image_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Makes a plain-coloured JPEG of the given size for testing.
Uint8List makeJpeg({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 60, 40));
  return img.encodeJpg(image, quality: 90);
}

void main() {
  group('compressImage', () {
    test('makes a thumbnail about 200px wide', () {
      final result = compressImage(makeJpeg(width: 1024, height: 768));

      final thumbnail = img.decodeImage(result.thumbnailBytes)!;
      expect(thumbnail.width, thumbnailWidth);
    });

    test('shrinks photos wider than 1024px', () {
      final result = compressImage(makeJpeg(width: 3000, height: 2000));

      final full = img.decodeImage(result.fullBytes)!;
      expect(full.width, fullImageWidth);
    });

    test('keeps the full photo under the Firestore size limit', () {
      final result = compressImage(makeJpeg(width: 3000, height: 2000));

      expect(result.fullBytes.length, lessThanOrEqualTo(maxImageBytes));
    });

    test('does not stretch tiny images', () {
      final result = compressImage(makeJpeg(width: 120, height: 80));

      final thumbnail = img.decodeImage(result.thumbnailBytes)!;
      expect(thumbnail.width, 120);
    });

    test('rejects files that are not images', () {
      expect(
        () => compressImage(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<ImageProcessingException>()),
      );
    });
  });
}
