import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _client = http.Client();
  final _auth = AuthService();

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    final token = _auth.token;
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  // ─── Auth ───────────────────────────────────────────────────────────────────

  Future<AuthResponse> register(String name, String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}');
    final response = await _client
        .post(uri, headers: _headers,
            body: jsonEncode({'name': name, 'email': email, 'password': password}))
        .timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) {
      final auth = AuthResponse.fromJson(jsonDecode(response.body));
      await _auth.saveAuth(auth);
      return auth;
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<AuthResponse> login(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}');
    final response = await _client
        .post(uri, headers: _headers,
            body: jsonEncode({'email': email, 'password': password}))
        .timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) {
      final auth = AuthResponse.fromJson(jsonDecode(response.body));
      await _auth.saveAuth(auth);
      return auth;
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<UserProfile> getMe() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.me}');
    final response = await _client.get(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) return UserProfile.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<List<DocumentHistoryItem>> getMyDocuments() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.myDocuments}');
    final response = await _client.get(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['documents'] as List)
          .map((e) => DocumentHistoryItem.fromJson(e))
          .toList();
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Upload Document ────────────────────────────────────────────────────────

  Future<UploadResponse> uploadDocument(File file) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.uploadDocument}');
    final request = http.MultipartRequest('POST', uri);
    final token = _auth.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) return UploadResponse.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── SSE Analysis Stream ────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> analyzeStream(String docId, String mode) async* {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.analyzeStream}/$docId?mode=$mode');
    final request = http.Request('GET', uri);
    final token = _auth.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    late http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Could not connect after 30s'),
      );
    } catch (e) {
      throw ApiException(0, 'Connection failed: $e');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw ApiException(response.statusCode, _parseError(body));
    }

    String eventName = '';
    final dataBuffer = StringBuffer();
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('event: ')) {
          eventName = line.substring(7).trim();
        } else if (line.startsWith('data: ')) {
          dataBuffer.write(line.substring(6).trim());
        } else if (line.isEmpty && dataBuffer.isNotEmpty) {
          try {
            final decoded = jsonDecode(dataBuffer.toString());
            yield {'event': eventName, 'data': decoded};
          } catch (_) {}
          dataBuffer.clear();
          eventName = '';
        }
      }
    }
  }

  // ─── Individual Analysis Endpoints ─────────────────────────────────────────

  Future<DocumentSummary> getDocumentSummary(String docId, String mode) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.documentSummary}/$docId?mode=$mode');
    final response = await _client.get(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) return DocumentSummary.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<RiskAnalysis> getRiskAnalysis(String docId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.riskAnalysis}/$docId');
    final response = await _client.get(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) return RiskAnalysis.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<ClauseFairness> getClauseFairness(String docId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.clauseFairness}/$docId');
    final response = await _client.get(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) return ClauseFairness.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<SafetyScore> getSafetyScore(String docId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.safetyScore}/$docId');
    final response = await _client.get(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) return SafetyScore.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Chat ───────────────────────────────────────────────────────────────────

  Future<ChatResponse> chatWithDocument(
      String docId, String question, List<Map<String, String>> history) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatWithDocument}');
    final response = await _client
        .post(uri, headers: _headers,
            body: jsonEncode({'document_id': docId, 'user_question': question, 'conversation_history': history}))
        .timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) return ChatResponse.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<LegalChatResponse> legalChat(
      String message, List<Map<String, String>> history, String language) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.legalChat}');
    final response = await _client
        .post(uri, headers: _headers,
            body: jsonEncode({'user_message': message, 'conversation_history': history, 'language': language}))
        .timeout(ApiConfig.receiveTimeout);
    if (response.statusCode == 200) return LegalChatResponse.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  Future<GuidanceResponse> getRequiredDocuments(String category) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.requiredDocuments}/$category');
    final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) return GuidanceResponse.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Feature A: Contract Safety Comparison ─────────────────────────────────

  Future<ContractComparison> compareContracts(
      String docIdA, String docIdB) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.compareContracts}');
    final response = await _client
        .post(uri, headers: _headers,
            body: jsonEncode({'document_id_a': docIdA, 'document_id_b': docIdB}))
        .timeout(ApiConfig.featureTimeout);
    if (response.statusCode == 200) return ContractComparison.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Feature B: Clause Rewriting ───────────────────────────────────────────

  Future<RewriteResult> getClauseRewrites(String docId, {String tone = 'standard'}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.clauseRewrites}/$docId?tone=$tone');
    final response = await _client.get(uri, headers: _headers).timeout(ApiConfig.featureTimeout);
    if (response.statusCode == 200) return RewriteResult.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Feature C: Smart Checklist ────────────────────────────────────────────

  Future<SmartChecklist> getSmartChecklist(String docId, {String docType = ''}) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.smartChecklist}/$docId?doc_type=$docType');
    final response = await _client.get(uri, headers: _headers).timeout(ApiConfig.featureTimeout);
    if (response.statusCode == 200) return SmartChecklist.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Feature D: Version Diff ───────────────────────────────────────────────

  Future<VersionDiff> getVersionDiff(String docIdV1, String docIdV2) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.versionDiff}');
    final response = await _client
        .post(uri, headers: _headers,
            body: jsonEncode({'document_id_v1': docIdV1, 'document_id_v2': docIdV2}))
        .timeout(ApiConfig.featureTimeout);
    if (response.statusCode == 200) return VersionDiff.fromJson(jsonDecode(response.body));
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['detail'] ?? json['error'] ?? 'Unknown error';
    } catch (_) {
      return body.isNotEmpty ? body : 'Unknown error';
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}