import 'dart:convert';
import 'dart:io';

/// One-shot: delete orphan `plantSpecies/{id}` catalog docs.
///
/// Keeps only species that are still referenced by at least one
/// `users/{uid}/plants/{plantId}` document (`species` or legacy `name`).
/// Shared catalog is create-only from the app and is not wiped on account
/// deletion, so orphans accumulate.
///
/// Usage:
///   dart run tools/cleanup_orphan_plant_species.dart --dry-run
///   dart run tools/cleanup_orphan_plant_species.dart
///
/// Auth: `gcloud auth application-default login`, or `FIREBASE_ACCESS_TOKEN`.
const _defaultProjectId = 'plant-logger-e0677';

String speciesDocIdFor(String species) {
  return species.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

Future<void> main(List<String> arguments) async {
  final options = _parseArguments(arguments);
  final dryRun =
      options.containsKey('dry-run') || arguments.contains('--dry-run');

  FirestoreRestClient? client;
  try {
    final projectId = options['project-id'] ?? _defaultProjectId;
    final accessToken = options['access-token'] ?? await _getAccessToken();
    client = FirestoreRestClient(
      projectId: projectId,
      accessToken: accessToken,
    );

    stdout.writeln(
      dryRun
          ? 'Dry-run: orphan plantSpecies не удаляются.'
          : 'Удаление orphan plantSpecies…',
    );

    final referencedIds = <String>{};
    final userIds = await client.listDocumentIds('users');
    stdout.writeln('Пользователей: ${userIds.length}');

    var plantsScanned = 0;
    for (final uid in userIds) {
      final plantIds = await client.listDocumentIds('users/$uid/plants');
      for (final plantId in plantIds) {
        plantsScanned++;
        final path = 'users/$uid/plants/$plantId';
        final doc = await client.getDocument(
          path,
          fieldPaths: const ['species', 'name'],
        );
        if (doc == null) continue;
        final fields =
            (doc['fields'] as Map<String, dynamic>?) ?? const {};
        final species = _readStringField(fields['species']) ??
            _readStringField(fields['name']);
        if (species == null || species.trim().isEmpty) continue;
        referencedIds.add(speciesDocIdFor(species));
      }
    }

    stdout.writeln(
      'Растений просмотрено: $plantsScanned, '
      'уникальных species id: ${referencedIds.length}',
    );

    final catalogDocs = await client.listDocuments('plantSpecies');
    stdout.writeln('Документов plantSpecies: ${catalogDocs.length}');

    final orphans = <String>[];
    for (final doc in catalogDocs) {
      final name = doc['name'] as String? ?? '';
      final id = client.documentPath(name).split('/').last;
      if (id.isEmpty) continue;
      if (!referencedIds.contains(id)) {
        orphans.add(id);
      }
    }

    orphans.sort();
    stdout.writeln('Сирот (к удалению): ${orphans.length}');
    for (final id in orphans) {
      stdout.writeln('${dryRun ? '[dry-run] ' : ''}plantSpecies/$id');
    }

    var deleted = 0;
    var failed = 0;
    if (!dryRun) {
      for (final id in orphans) {
        try {
          await client.deleteDocument('plantSpecies/$id');
          deleted++;
        } catch (error) {
          failed++;
          stderr.writeln('Не удалось удалить plantSpecies/$id: $error');
        }
      }
    }

    stdout.writeln(
      dryRun
          ? 'Готово (dry-run). К удалению: ${orphans.length}.'
          : 'Готово. Удалено: $deleted, ошибок: $failed, '
              'оставлено (есть на растениях): '
              '${catalogDocs.length - orphans.length}.',
    );
    if (failed > 0) exitCode = 1;
  } on Object catch (error) {
    stderr.writeln('Очистка не удалась: $error');
    exitCode = 1;
  } finally {
    client?.close();
  }
}

String? _readStringField(Object? value) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  final raw = map['stringValue'];
  if (raw is String) return raw;
  return null;
}

Map<String, String> _parseArguments(List<String> arguments) {
  final options = <String, String>{};

  for (final argument in arguments) {
    if (argument == '--dry-run') {
      options['dry-run'] = 'true';
      continue;
    }
    if (!argument.startsWith('--') || !argument.contains('=')) {
      continue;
    }

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

  String get _commitUrl => 'https://firestore.googleapis.com/v1/projects/'
      '${Uri.encodeComponent(projectId)}/databases/(default)/documents:commit';

  String resourceName(String documentPath) =>
      'projects/$projectId/databases/(default)/documents/$documentPath';

  Future<List<String>> listDocumentIds(String collectionPath) async {
    final documents = await listDocuments(collectionPath);
    return documents
        .map((doc) => documentPath(doc['name'] as String).split('/').last)
        .toList();
  }

  Future<List<Map<String, dynamic>>> listDocuments(String path) async {
    final separator = path.lastIndexOf('/');
    final parentPath = separator < 0 ? '' : path.substring(0, separator);
    final collectionId = separator < 0 ? path : path.substring(separator + 1);
    if (collectionId.isEmpty) {
      throw ArgumentError.value(path, 'path', 'Ожидался путь к коллекции');
    }

    final documents = <Map<String, dynamic>>[];
    String? pageToken;

    do {
      final collectionSegment = parentPath.isEmpty
          ? Uri.encodeComponent(collectionId)
          : '${_encodePath(parentPath)}/${Uri.encodeComponent(collectionId)}';
      final buffer = StringBuffer(
        '$_documentsBase/$collectionSegment?pageSize=300',
      );
      if (pageToken != null && pageToken.isNotEmpty) {
        buffer.write('&pageToken=${Uri.encodeQueryComponent(pageToken)}');
      }

      final response = await _requestJson('GET', Uri.parse(buffer.toString()));
      final page = response?['documents'] as List<dynamic>? ?? const [];
      documents.addAll(page.cast<Map<String, dynamic>>());
      pageToken = response?['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);

    return documents;
  }

  Future<Map<String, dynamic>?> getDocument(
    String documentPath, {
    List<String>? fieldPaths,
  }) async {
    final buffer = StringBuffer(
      '$_documentsBase/${_encodePath(documentPath)}',
    );
    if (fieldPaths != null && fieldPaths.isNotEmpty) {
      buffer.write('?');
      for (var i = 0; i < fieldPaths.length; i++) {
        if (i > 0) buffer.write('&');
        buffer.write(
          'mask.fieldPaths=${Uri.encodeQueryComponent(fieldPaths[i])}',
        );
      }
    }

    return _requestJson(
      'GET',
      Uri.parse(buffer.toString()),
      allowNotFound: true,
    );
  }

  Future<void> deleteDocument(String documentPath) async {
    await _requestJson(
      'POST',
      Uri.parse(_commitUrl),
      body: <String, dynamic>{
        'writes': <Map<String, dynamic>>[
          <String, dynamic>{
            'delete': resourceName(documentPath),
          },
        ],
      },
    );
  }

  String documentPath(String resourceName) {
    const marker = '/documents/';
    final markerIndex = resourceName.indexOf(marker);
    if (markerIndex < 0) {
      throw FormatException('Некорректное имя документа: $resourceName');
    }
    return resourceName.substring(markerIndex + marker.length);
  }

  Future<Map<String, dynamic>?> _requestJson(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool allowNotFound = false,
  }) async {
    final request = await _httpClient.openUrl(method, uri);
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $accessToken')
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

    if (body != null) {
      final payload = utf8.encode(jsonEncode(body));
      request.headers.contentType = ContentType.json;
      request.contentLength = payload.length;
      request.add(payload);
    }

    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    if (allowNotFound && response.statusCode == 404) {
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Firestore вернул ${response.statusCode}: $responseBody',
        uri: uri,
      );
    }

    if (responseBody.isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  String _encodePath(String path) {
    return path.split('/').map(Uri.encodeComponent).join('/');
  }

  void close() => _httpClient.close();
}
