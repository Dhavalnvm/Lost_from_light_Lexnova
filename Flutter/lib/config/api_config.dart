class ApiConfig {
  static const String baseUrl = 'https://a7b8-106-192-123-53.ngrok-free.app/api/v1';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String register        = '/auth/register';
  static const String login           = '/auth/login';
  static const String me              = '/auth/me';
  static const String myDocuments     = '/auth/my-documents';

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

  // ── New Features ───────────────────────────────────────────────────────────
  static const String compareContracts = '/compare-contracts';
  static const String clauseRewrites   = '/clause-rewrites';
  static const String smartChecklist   = '/smart-checklist';
  static const String versionDiff      = '/version-diff';

  // ── Timeouts ───────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 120);
  static const Duration featureTimeout = Duration(seconds: 240);
}