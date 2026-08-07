import 'dart:convert';
import 'dart:io';

/// One-shot: remove obsolete plant migration flags from Firestore.
///
/// Deletes fields `careHistoryMigrated` and `botanicalFieldsMigrated` on
/// `users/{uid}/plants/{plantId}` documents. Does not touch other fields.
///
/// Usage:
///   dart run tools/cleanup_migration_flags.dart --dry-run
///   dart run tools/cleanup_migration_flags.dart
///   dart run tools/cleanup_migration_flags.dart --uid=USER_ID
///
/// Auth: `gcloud auth application-default login`, or `FIREBASE_ACCESS_TOKEN`.
const _defaultProjectId = 'plant-logger-e0677';
const _fieldsToDelete = <String>[
  'careHistoryMigrated',
  'botanicalFieldsMigrated',
];

Future<void> main(List<String> arguments) async {
  final options = _parseArguments(arguments);
  final dryRun = options.containsKey('dry-run') ||
      arguments.contains('--dry-run');
  final uidFilter = options['uid'];

  FirestoreRestClient? client;
  try {
    final projectId = options['project-id'] ?? _defaultProjectId;
    final accessToken = options['access-token'] ?? await _getAccessToken();
    client = FirestoreRestClient(
      projectId: projectId,
      accessToken: accessToken,
    );

    final userIds = uidFilter != null && uidFilter.isNotEmpty
        ? <String>[uidFilter]
        : await client.listDocumentIds('users');

    var scanned = 0;
    var withFlags = 0;
    var updated = 0;
    var skipped = 0;
    var failed = 0;

    stdout.writeln(
      dryRun
          ? 'Dry-run: поля не удаляются.'
          : 'Удаление флагов: ${_fieldsToDelete.join(', ')}',
    );
    stdout.writeln('Пользователей: ${userIds.length}');

    for (final uid in userIds) {
      final plantIds = await client.listDocumentIds('users/$uid/plants');
      for (final plantId in plantIds) {
        scanned++;
        final documentPath = 'users/$uid/plants/$plantId';
        final present = await client.presentFields(documentPath, _fieldsToDelete);
        if (present.isEmpty) {
          skipped++;
          continue;
        }

        withFlags++;
        stdout.writeln(
          '${dryRun ? '[dry-run] ' : ''}'
          '$documentPath → удалить: ${present.join(', ')}',
        );

        if (!dryRun) {
          await client.deleteFields(documentPath, present);
          final remaining =
              await client.presentFields(documentPath, _fieldsToDelete);
          if (remaining.isNotEmpty) {
            failed++;
            stderr.writeln(
              'НЕ удалилось на $documentPath: ${remaining.join(', ')}',
            );
          } else {
            updated++;
          }
        }
      }
    }

    stdout.writeln(
      'Готово. Просмотрено растений: $scanned, '
      'с флагами: $withFlags, '
      '${dryRun ? 'к удалению' : 'подтверждённо удалено'}: '
      '${dryRun ? withFlags : updated}, '
      'без флагов: $skipped'
      '${failed > 0 ? ', ошибок: $failed' : ''}.',
    );
    if (failed > 0) {
      exitCode = 1;
    }
  } on Object catch (error) {
    stderr.writeln('Очистка не удалась: $error');
    exitCode = 1;
  } finally {
    client?.close();
  }
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
    final documents = await _listDocuments(collectionPath);
    return documents
        .map((doc) => documentPath(doc['name'] as String).split('/').last)
        .toList();
  }

  Future<List<String>> presentFields(
    String documentPath,
    List<String> fieldPaths,
  ) async {
    final document = await getDocument(documentPath, fieldPaths: fieldPaths);
    if (document == null) return const [];
    final fields = (document['fields'] as Map<String, dynamic>?) ?? const {};
    return fieldPaths.where(fields.containsKey).toList();
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

    final response = await _requestJson(
      'GET',
      Uri.parse(buffer.toString()),
      allowNotFound: true,
    );
    return response;
  }

  Future<List<Map<String, dynamic>>> _listDocuments(String path) async {
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

  /// Deletes [fieldPaths] via `documents:commit` update + updateMask omission.
  Future<void> deleteFields(
    String documentPath,
    List<String> fieldPaths,
  ) async {
    if (fieldPaths.isEmpty) return;

    await _requestJson(
      'POST',
      Uri.parse(_commitUrl),
      body: <String, dynamic>{
        'writes': <Map<String, dynamic>>[
          <String, dynamic>{
            'updateMask': <String, dynamic>{
              'fieldPaths': fieldPaths,
            },
            'update': <String, dynamic>{
              'name': resourceName(documentPath),
              'fields': <String, dynamic>{},
            },
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
