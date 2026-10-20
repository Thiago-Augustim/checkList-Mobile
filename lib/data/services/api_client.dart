import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/checklist_models.dart';

class ApiUnauthorizedException implements Exception {
  final String message;
  const ApiUnauthorizedException(this.message);
}

class ApiClient {
  final http.Client _httpClient;
  String baseUrl;

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl();

  /// No Emulador Android, o localhost da máquina hospedeira (Windows) é 10.0.2.2
  static String defaultBaseUrl() {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  Future<AuthSessionModel> login(String username, String senha) async {
    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
            HttpHeaders.acceptHeader: 'application/json',
          },
          body: jsonEncode({'username': username, 'senha': senha}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSessionModel.fromJson(jsonMap);
    }
    throw Exception('Falha no login (${response.statusCode}): ${response.body}');
  }

  Future<AuthSessionModel> renovarToken(String refreshToken) async {
    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
            HttpHeaders.acceptHeader: 'application/json',
          },
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthSessionModel.fromJson(jsonMap);
    }
    throw const ApiUnauthorizedException('Sessão expirada.');
  }

  Future<CatalogoOfflineModel> baixarCatalogos(String accessToken) async {
    final response = await _httpClient
        .get(
          Uri.parse('$baseUrl/sync/catalogos'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
            HttpHeaders.acceptHeader: 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ApiUnauthorizedException('Token expirado.');
    }
    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return CatalogoOfflineModel.fromJson(jsonMap);
    }
    throw Exception(
      'Erro ao baixar catálogos (${response.statusCode}): ${response.body}',
    );
  }

  /// Etapa 1 do Upsync Offline: envia o JSON leve do checklist e retorna a lista de fotos pendentes.
  Future<List<String>> enviarChecklistEtapa1(
    String accessToken,
    ChecklistFilaItemModel checklist,
  ) async {
    final response = await _httpClient
        .post(
          Uri.parse('$baseUrl/sync/checklists'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
            HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
            HttpHeaders.acceptHeader: 'application/json',
          },
          body: jsonEncode(checklist.toSyncApiPayload()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ApiUnauthorizedException('Token expirado.');
    }
    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      final rawIds =
          jsonMap['fotosPendentesIds'] as List<dynamic>? ?? <dynamic>[];
      return rawIds.map((e) => e.toString()).toList();
    }
    throw Exception(
      'Falha ao sincronizar checklist (${response.statusCode}): ${response.body}',
    );
  }

  /// Etapa 2 do Upsync Offline: envia o arquivo binário comprimido de uma foto de avaria via Multipart.
  Future<void> enviarFotoEtapa2(
    String accessToken,
    String fotoId,
    List<int> bytesJpeg,
  ) async {
    final uri = Uri.parse('$baseUrl/sync/fotos/$fotoId');
    final request = http.MultipartRequest('POST', uri);
    request.headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    request.files.add(
      http.MultipartFile.fromBytes(
        'arquivo',
        bytesJpeg,
        filename: '$fotoId.jpg',
      ),
    );

    final streamedResponse =
        await _httpClient.send(request).timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ApiUnauthorizedException('Token expirado.');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao enviar foto $fotoId (${response.statusCode}): ${response.body}',
      );
    }
  }
}
