import 'dart:convert';
import 'dart:io';

/// Full export of a user's Firestore data + all Storage photos.
///
/// Usage:
///   dart run tools/export_full.dart --uid=<uid>
///
/// Optional:
///   --project-id=plant-logger-e0677
///   --access-token=<token>
///   --out-dir=exports/full_backup
///
/// Outputs:
///   <out-dir>/firestore.json          — all Firestore documents (full fields)
///   <out-dir>/photos/                 — all Storage images downloaded
///   <out-dir>/manifest.json           — summary + photo URL mapping
const _defaultProjectId = 'plant-logger-e0677';
const _defaultOutDir = 'exports/full_backup';

/// Top-level collections under users/<uid>.
const _topLevelCollections = <String>[
  'plants',
  'propagations',
  'fertilizerComponents',
  'soils',
  'components',
  'wishList',
  'financeEntries',
  'friends',
  'friendRequests',
  'incomingGifts',
  'outgoingGifts',
];

/// Sub-collections nested under a plant document.
const _plantSubCollections = <String>[
  'notes',
  'growthEvents',
  'manipulations',
  'watering',
  'fertilizing',
  'repotting',
];

/// Sub-collections nested under a propagation document.
const _propagationSubCollections = <String>[
  'notes',
  'stageHistory',
];

Future<void> main(List<String> arguments) async {
  final options = _parseArguments(arguments);
  final uid = options['uid'];

  if (uid == null || uid.isEmpty) {
    stderr.writeln(
      'Укажите UID: dart run tools/export_full.dart --uid=<uid>',
    );
    exitCode = 64;
    return;
  }

  FirestoreRestClient? client;
  try {
    final projectId = options['project-id'] ?? _defaultProjectId;
    final outDir = options['out-dir'] ?? _defaultOutDir;
    final accessToken = options['access-token'] ?? await _getAccessToken();
    client = FirestoreRestClient(
      projectId: projectId,
      accessToken: accessToken,
    );

    final outDirFile = Directory(outDir);
    await outDirFile.create(recursive: true);
    final photosDir = Directory('$outDir/photos');
    await photosDir.create(recursive: true);

    final backup = <String, dynamic>{};
    final photoUrls = <String, String>{};
    var photoCount = 0;

    // 1. User profile document.
    final userDoc = await client.getDocument('users/$uid');
    if (userDoc != null) {
      backup['user'] = userDoc;
    }

    // 2. Top-level collections.
    for (final collection in _topLevelCollections) {
      final docs = await client.listDocuments('users/$uid/$collection');
      if (docs.isEmpty) continue;
      backup[collection] = docs;

      // 3. Nested sub-collections per document.
      final subCollections = collection == 'plants'
          ? _plantSubCollections
          : collection == 'propagations'
              ? _propagationSubCollections
              : const <String>[];
      if (subCollections.isEmpty) continue;

      for (final doc in docs) {
        final docId = doc['id'] as String;
        final nested = <String, dynamic>{};
        for (final sub in subCollections) {
          final subDocs = await client
              .listDocuments('users/$uid/$collection/$docId/$sub');
          if (subDocs.isNotEmpty) nested[sub] = subDocs;
        }
        if (nested.isNotEmpty) {
          backup['${collection}_$docId'] = nested;
        }
      }
    }

    // 4. Download all photos from Storage.
    final storageItems = await _listStorageItems(accessToken, projectId);
    for (final item in storageItems) {
      final name = item['name'] as String;
      if (!name.startsWith('plants/')) continue;
      final fileName = name.split('/').last;
      final localPath = '$outDir/photos/$fileName';
      final ok = await _downloadStorageFile(
        accessToken,
        projectId,
        name,
        localPath,
      );
      if (ok) {
        photoCount++;
        photoUrls[name] = localPath;
      }
    }

    // 5. Write manifest + firestore.json.
    final manifest = <String, dynamic>{
      'projectId': projectId,
      'uid': uid,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'collections': backup.keys.toList()..sort(),
      'photoCount': photoCount,
      'photos': photoUrls,
    };

    final firestoreFile = File('$outDir/firestore.json');
    await firestoreFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
    );
    final manifestFile = File('$outDir/manifest.json');
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    stdout.writeln(
      'Экспорт завершён.\n'
      '  Firestore: ${firestoreFile.absolute.path}\n'
      '  Фото: $photoCount файлов в ${photosDir.absolute.path}\n'
      '  Манифест: ${manifestFile.absolute.path}',
    );
  } on Object catch (error, stackTrace) {
    stderr.writeln('Не удалось выполнить полный экспорт: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  } finally {
    client?.close();
  }
}

String _documentId(String resourceName) {
  return resourceName.split('/').last;
}

Future<List<Map<String, dynamic>>> _listStorageItems(
  String accessToken,
  String projectId,
) async {
  final bucket = '$projectId.firebasestorage.app';
  final client = HttpClient();
  try {
    final items = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final query = <String, String>{
        'prefix': 'plants/',
        if (pageToken != null) 'pageToken': pageToken,
      };
      final uri = Uri.parse(
        'https://firebasestorage.googleapis.com/v0/b/$bucket/o',
      ).replace(queryParameters: query);
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Storage list вернул ${response.statusCode}: $body',
          uri: uri,
        );
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      items.addAll(
        (json['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>(),
      );
      pageToken = json['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);
    return items;
  } finally {
    client.close();
  }
}

Future<bool> _downloadStorageFile(
  String accessToken,
  String projectId,
  String objectName,
  String localPath,
) async {
  final bucket = '$projectId.firebasestorage.app';
  final client = HttpClient();
  try {
    final encodedName = objectName.split('/').map(Uri.encodeComponent).join('/');
    final uri = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedName'
      '?alt=media',
    );
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await utf8.decoder.bind(response).join();
      stderr.writeln('  Пропуск $objectName: ${response.statusCode} $body');
      return false;
    }
    final file = File(localPath);
    await file.create(recursive: true);
    final sink = file.openWrite();
    await response.pipe(sink);
    await sink.close();
    return true;
  } on Object catch (error) {
    stderr.writeln('  Ошибка скачивания $objectName: $error');
    return false;
  } finally {
    client.close();
  }
}

Map<String, String> _parseArguments(List<String> arguments) {
  final options = <String, String>{};
  for (final argument in arguments) {
    if (!argument.startsWith('--') || !argument.contains('=')) continue;
    final separator = argument.indexOf('=');
    options[argument.substring(2, separator)] =
        argument.substring(separator + 1);
  }
  return options;
}

Future<String> _getAccessToken() async {
  final environmentToken = Platform.environment['FIREBASE_ACCESS_TOKEN'];
  if (environmentToken != null && environmentToken.isNotEmpty) {
    return environmentToken;
  }

  ProcessResult result;
  try {
    result = await Process.run(
      'gcloud',
      const ['auth', 'application-default', 'print-access-token'],
      runInShell: Platform.isWindows,
    );
  } on ProcessException catch (error) {
    throw StateError(
      'Не найден токен доступа. Задайте FIREBASE_ACCESS_TOKEN или выполните '
      '"gcloud auth application-default login". Причина: ${error.message}',
    );
  }

  final token = (result.stdout as String).trim();
  if (result.exitCode != 0 || token.isEmpty) {
    final details = (result.stderr as String).trim();
    throw StateError(
      'Не удалось получить токен через gcloud. Выполните '
      '"gcloud auth application-default login". $details',
    );
  }
  return token;
}

class FirestoreRestClient {
  FirestoreRestClient({
    required this.projectId,
    required this.accessToken,
  });

  final String projectId;
  final String accessToken;
  final HttpClient _httpClient = HttpClient();

  String get _documentsBase => 'https://firestore.googleapis.com/v1/projects/'
      '${Uri.encodeComponent(projectId)}/databases/(default)/documents';

  Future<Map<String, dynamic>?> getDocument(String path) async {
    final uri = Uri.parse('$_documentsBase/${_encodePath(path)}');
    final response = await _requestJson('GET', uri);
    if (response.isEmpty) return null;
    return _decodeDocument(response);
  }

  Future<List<Map<String, dynamic>>> listDocuments(String path) async {
    final separator = path.lastIndexOf('/');
    if (separator < 0) {
      throw ArgumentError.value(path, 'path', 'Ожидался путь к коллекции');
    }
    final parentPath = path.substring(0, separator);
    final collectionId = path.substring(separator + 1);
    final documents = <Map<String, dynamic>>[];
    String? pageToken;

    do {
      final query = <String, String>{
        'pageSize': '1000',
        if (pageToken != null) 'pageToken': pageToken,
      };
      final base = Uri.parse(
        '$_documentsBase/${_encodePath(parentPath)}/'
        '${Uri.encodeComponent(collectionId)}',
      ).replace(queryParameters: query);
      final response = await _requestJson('GET', base);
      final page = response['documents'] as List<dynamic>? ?? const [];
      for (final doc in page.cast<Map<String, dynamic>>()) {
        documents.add(_decodeDocument(doc));
      }
      pageToken = response['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);

    return documents;
  }

  Map<String, dynamic> _decodeDocument(Map<String, dynamic> document) {
    final path = _documentPath(document['name'] as String);
    final fields = _decodeFields(
      (document['fields'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    );
    return <String, dynamic>{
      'id': path.split('/').last,
      'path': path,
      'fields': fields,
    };
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient.openUrl(method, uri);
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $accessToken')
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Firestore вернул ${response.statusCode}: $responseBody',
        uri: uri,
      );
    }
    if (responseBody.isEmpty) return <String, dynamic>{};
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  String _encodePath(String path) {
    return path.split('/').map(Uri.encodeComponent).join('/');
  }

  String _documentPath(String resourceName) {
    const marker = '/documents/';
    final markerIndex = resourceName.indexOf(marker);
    if (markerIndex < 0) {
      throw FormatException('Некорректное имя документа: $resourceName');
    }
    return resourceName.substring(markerIndex + marker.length);
  }

  Map<String, dynamic> _decodeFields(Map<String, dynamic> fields) {
    return fields.map(
      (key, value) => MapEntry(
        key,
        _decodeValue(value as Map<String, dynamic>),
      ),
    );
  }

  dynamic _decodeValue(Map<String, dynamic> value) {
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue'] as String);
    }
    if (value.containsKey('doubleValue')) {
      final doubleValue = value['doubleValue'];
      if (doubleValue is num) return doubleValue;
      return null;
    }
    if (value.containsKey('timestampValue')) return value['timestampValue'];
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('arrayValue')) {
      final array = value['arrayValue'] as Map<String, dynamic>;
      final values = array['values'] as List<dynamic>? ?? const [];
      return values
          .map((item) => _decodeValue(item as Map<String, dynamic>))
          .toList();
    }
    if (value.containsKey('mapValue')) {
      final map = value['mapValue'] as Map<String, dynamic>;
      return _decodeFields(
        (map['fields'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
      );
    }
    return null;
  }

  void close() => _httpClient.close();
}
