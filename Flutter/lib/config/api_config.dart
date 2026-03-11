class ApiConfig {
  static const String baseUrl =
      'https://d27a-43-227-21-21.ngrok-free.app/api/v1';

  /// WebSocket base URL — derived from baseUrl at runtime.
  /// Strips /api/v1 and swaps https→wss (or http→ws).
  static String get wsBase => baseUrl
      .replaceFirst('/api/v1', '')
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String register    = '/auth/register';
  static const String login       = '/auth/login';
  static const String me          = '/auth/me';
  static const String myDocuments = '/auth/my-documents';

  // ── Document Analysis ──────────────────────────────────────────────────────
  static const String uploadDocument   = '/upload-document';
  static const String analyzeStream    = '/analyze-stream';
  static const String documentSummary  = '/document-summary';
  static const String riskAnalysis     = '/risk-analysis';
  static const String clauseFairness   = '/clause-fairness';
  static const String safetyScore      = '/safety-score';
  static const String chatWithDocument = '/chat-with-document';

  // ── Guidance & Chat ────────────────────────────────────────────────────────
  static const String requiredDocuments  = '/required-documents';
  static const String documentCategories = '/document-categories';
  static const String legalChat          = '/legal-chat';
  static const String translateResponse  = '/translate-response';
  static const String documentTypes      = '/document-types';

  // ── Features ───────────────────────────────────────────────────────────────
  static const String compareContracts = '/compare-contracts';
  static const String clauseRewrites   = '/clause-rewrites';
  static const String smartChecklist   = '/smart-checklist';
  static const String versionDiff      = '/version-diff';

  // ── Group Discussion ───────────────────────────────────────────────────────
  static const String groupChatCreate = '/group-chat/create';
  static const String groupChatJoin   = '/group-chat/join';

  static String groupChatRoom(String code) =>
      '/group-chat/${code.toUpperCase()}';

  static String groupChatHistory(String code) =>
      '/group-chat/${code.toUpperCase()}/history';

  /// WebSocket URL for group discussion.
  /// user_id and display_name are sent as query params
  /// (browsers/apps cannot set headers on WebSocket connections).
  static String groupChatWs(String code, String userId, String displayName) =>
      '$wsBase/api/v1/group-chat/ws/${code.toUpperCase()}'
      '?user_id=${Uri.encodeComponent(userId)}'
      '&display_name=${Uri.encodeComponent(displayName)}';

  // ── Timeouts ───────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 120);
  static const Duration featureTimeout = Duration(seconds: 240);
}