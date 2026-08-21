import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/plant.dart';
import 'package:plontukrot/models/plant_archive_reason.dart';
import 'package:plontukrot/models/plant_photo.dart';

void main() {
  group('Plant archive and group members', () {
    test('parses archive fields from snake_case JSON', () {
      final plant = Plant.fromMap('plant-1', {
        'genus': 'Hoya',
        'species': 'carnosa',
        'nickname': 'Carnosa',
        'stage': 2,
        'archived_at': '2026-08-21T10:00:00.000Z',
        'expires_at': '2028-08-20T10:00:00.000Z',
        'archive_reason': 'merged',
        'archive_note': 'Merged into group',
        'merged_into_plant_id': 'group-1',
      });

      expect(plant.isArchived, isTrue);
      expect(plant.archivedAt, DateTime.utc(2026, 8, 21, 10, 0, 0));
      expect(plant.expiresAt, DateTime.utc(2028, 8, 20, 10, 0, 0));
      expect(plant.archiveReason, PlantArchiveReason.merged);
      expect(plant.archiveNote, 'Merged into group');
      expect(plant.mergedIntoPlantId, 'group-1');
    });

    test('parses group members from snake_case and camelCase JSON', () {
      final plant = Plant.fromMap('group-1', {
        'genus': 'Hoya',
        'species': 'carnosa',
        'nickname': 'Tricolor + Krimson Queen',
        'stage': 2,
        'members': [
          {
            'cultivar': 'Krimson Queen',
            'variegation': 1,
            'source_plant_id': 'src-1',
          },
          {
            'cultivar': 'Tricolor',
            'variegation': 2,
            'sourcePlantId': 'src-2',
          },
        ],
      });

      expect(plant.isGroup, isTrue);
      expect(plant.members.length, 2);
      expect(plant.members[0].cultivar, 'Krimson Queen');
      expect(plant.members[0].sourcePlantId, 'src-1');
      expect(plant.members[1].cultivar, 'Tricolor');
      expect(plant.members[1].sourcePlantId, 'src-2');
    });
  });
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
