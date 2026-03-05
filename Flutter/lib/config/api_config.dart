class ApiConfig {
  // Change this to your machine's IP when running on physical device
  // Use 10.0.2.2 for Android emulator, localhost for web
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Endpoints
  static const String uploadDocument = '/upload-document';
  static const String documentSummary = '/document-summary';
  static const String riskAnalysis = '/risk-analysis';
  static const String clauseFairness = '/clause-fairness';
  static const String safetyScore = '/safety-score';
  static const String chatWithDocument = '/chat-with-document';
  static const String requiredDocuments = '/required-documents';
  static const String documentCategories = '/document-categories';
  static const String legalChat = '/legal-chat';
  static const String translateResponse = '/translate-response';
  static const String documentTypes = '/document-types';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 120);
}
