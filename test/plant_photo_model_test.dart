import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/plant.dart';
import 'package:plontukrot/models/plant_photo.dart';

void main() {
  group('Plant.listImageUrl', () {
    test('prefers non-empty thumb over full', () {
      const plant = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'M',
        stage: 1,
        imageUrl: 'https://example.com/full.jpg',
        imageThumbUrl: 'https://example.com/thumb.jpg',
      );
      expect(plant.listImageUrl, 'https://example.com/thumb.jpg');
    });

    test('falls back to full when thumb missing', () {
      const plant = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'M',
        stage: 1,
        imageUrl: 'https://example.com/full.jpg',
      );
      expect(plant.listImageUrl, 'https://example.com/full.jpg');
    });

    test('falls back to full when thumb is blank', () {
      const plant = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'M',
        stage: 1,
        imageUrl: 'https://example.com/full.jpg',
        imageThumbUrl: '   ',
      );
      expect(plant.listImageUrl, 'https://example.com/full.jpg');
    });

    test('returns null when both missing', () {
      const plant = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'M',
        stage: 1,
      );
      expect(plant.listImageUrl, isNull);
    });
  });

  group('Plant.galleryPhotos', () {
    test('returns images array when present', () {
      final added = DateTime.utc(2026, 1, 2);
      final plant = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'M',
        stage: 1,
        imageUrl: 'https://example.com/cover.jpg',
        images: [
          PlantPhoto(
            id: 'p1',
            imageUrl: 'https://example.com/p1.jpg',
            imageThumbUrl: 'https://example.com/p1_t.jpg',
            addedAt: added,
          ),
        ],
      );
      expect(plant.galleryPhotos, hasLength(1));
      expect(plant.galleryPhotos.single.id, 'p1');
    });

    test('synthesizes legacy cover when images empty', () {
      final created = DateTime.utc(2025, 6, 1);
      final plant = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'M',
        stage: 1,
        imageUrl: 'https://example.com/full.jpg',
        imageThumbUrl: 'https://example.com/thumb.jpg',
        createdAt: created,
      );
      final photos = plant.galleryPhotos;
      expect(photos, hasLength(1));
      expect(photos.single.id, PlantPhoto.legacyId);
      expect(photos.single.imageUrl, 'https://example.com/full.jpg');
      expect(photos.single.imageThumbUrl, 'https://example.com/thumb.jpg');
      expect(photos.single.isLegacy, isTrue);
    });

    test('returns empty when no cover and no images', () {
      const plant = Plant(
        id: '1',
        genus: 'Monstera',
        species: 'deliciosa',
        nickname: 'M',
        stage: 1,
      );
      expect(plant.galleryPhotos, isEmpty);
    });
  });

  group('PlantPhoto.fromMap', () {
    test('uses full url when thumb missing', () {
      final photo = PlantPhoto.fromMap({
        'id': 'abc',
        'imageUrl': 'https://example.com/full.jpg',
        'addedAt': DateTime.utc(2026, 3, 1),
      });
      expect(photo.imageUrl, 'https://example.com/full.jpg');
      expect(photo.imageThumbUrl, 'https://example.com/full.jpg');
    });

    test('keeps explicit thumb', () {
      final photo = PlantPhoto.fromMap({
        'id': 'abc',
        'imageUrl': 'https://example.com/full.jpg',
        'imageThumbUrl': 'https://example.com/thumb.jpg',
        'addedAt': DateTime.utc(2026, 3, 1),
      });
      expect(photo.imageThumbUrl, 'https://example.com/thumb.jpg');
    });
  });
}
