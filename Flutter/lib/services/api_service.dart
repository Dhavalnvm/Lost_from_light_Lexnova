import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _client = http.Client();

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ─── Upload Document ────────────────────────────────────────────────────────

  Future<UploadResponse> uploadDocument(File file) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.uploadDocument}');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return UploadResponse.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Document Summary ───────────────────────────────────────────────────────

  Future<DocumentSummary> getDocumentSummary(String docId, String mode) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.documentSummary}/$docId?mode=$mode');
    final response = await _client.get(uri).timeout(ApiConfig.receiveTimeout);

    if (response.statusCode == 200) {
      return DocumentSummary.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Risk Analysis ──────────────────────────────────────────────────────────

  Future<RiskAnalysis> getRiskAnalysis(String docId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.riskAnalysis}/$docId');
    final response = await _client.get(uri).timeout(ApiConfig.receiveTimeout);

    if (response.statusCode == 200) {
      return RiskAnalysis.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Clause Fairness ────────────────────────────────────────────────────────

  Future<ClauseFairness> getClauseFairness(String docId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.clauseFairness}/$docId');
    final response = await _client.get(uri).timeout(ApiConfig.receiveTimeout);

    if (response.statusCode == 200) {
      return ClauseFairness.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Safety Score ───────────────────────────────────────────────────────────

  Future<SafetyScore> getSafetyScore(String docId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.safetyScore}/$docId');
    final response = await _client.get(uri).timeout(ApiConfig.receiveTimeout);

    if (response.statusCode == 200) {
      return SafetyScore.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Chat With Document ─────────────────────────────────────────────────────

  Future<ChatResponse> chatWithDocument(
    String docId,
    String question,
    List<Map<String, String>> history,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatWithDocument}');
    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'document_id': docId,
            'user_question': question,
            'conversation_history': history,
          }),
        )
        .timeout(ApiConfig.receiveTimeout);

    if (response.statusCode == 200) {
      return ChatResponse.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Required Documents ─────────────────────────────────────────────────────

  Future<GuidanceResponse> getRequiredDocuments(String category) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.requiredDocuments}/$category');
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return GuidanceResponse.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

  // ─── Legal Chatbot ──────────────────────────────────────────────────────────

  Future<LegalChatResponse> legalChat(
    String message,
    List<Map<String, String>> history,
    String language,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.legalChat}');
    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'user_message': message,
            'conversation_history': history,
            'language': language,
          }),
        )
        .timeout(ApiConfig.receiveTimeout);

    if (response.statusCode == 200) {
      return LegalChatResponse.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, _parseError(response.body));
  }

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
