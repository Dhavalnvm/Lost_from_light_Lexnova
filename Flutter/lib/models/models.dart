// ─── Upload ───────────────────────────────────────────────────────────────────

class UploadResponse {
  final String documentId;
  final String filename;
  final int numberOfPages;
  final int numberOfChunks;
  final String fileType;
  final String status;
  final String message;

  UploadResponse({
    required this.documentId,
    required this.filename,
    required this.numberOfPages,
    required this.numberOfChunks,
    required this.fileType,
    required this.status,
    required this.message,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) => UploadResponse(
        documentId: json['document_id'],
        filename: json['filename'],
        numberOfPages: json['number_of_pages'],
        numberOfChunks: json['number_of_chunks'],
        fileType: json['file_type'],
        status: json['status'],
        message: json['message'],
      );
}

// ─── Summary ──────────────────────────────────────────────────────────────────

class PageSummary {
  final int pageNumber;
  final String summary;
  PageSummary({required this.pageNumber, required this.summary});
  factory PageSummary.fromJson(Map<String, dynamic> json) =>
      PageSummary(pageNumber: json['page_number'], summary: json['summary']);
}

class ClauseItem {
  final String clauseType;
  final String extractedText;
  final int? pageNumber;
  ClauseItem({required this.clauseType, required this.extractedText, this.pageNumber});
  factory ClauseItem.fromJson(Map<String, dynamic> json) => ClauseItem(
        clauseType: json['clause_type'],
        extractedText: json['extracted_text'],
        pageNumber: json['page_number'],
      );
}

class DocumentSummary {
  final String documentId;
  final String mode;
  final String summary;
  final List<PageSummary> pageSummaries;
  final List<ClauseItem> importantClauses;
  final List<String> keyObligations;
  final List<String> keyRights;

  DocumentSummary({
    required this.documentId,
    required this.mode,
    required this.summary,
    required this.pageSummaries,
    required this.importantClauses,
    required this.keyObligations,
    required this.keyRights,
  });

  factory DocumentSummary.fromJson(Map<String, dynamic> json) => DocumentSummary(
        documentId: json['document_id'],
        mode: json['mode'],
        summary: json['summary'],
        pageSummaries: (json['page_summaries'] as List)
            .map((e) => PageSummary.fromJson(e))
            .toList(),
        importantClauses: (json['important_clauses'] as List)
            .map((e) => ClauseItem.fromJson(e))
            .toList(),
        keyObligations: List<String>.from(json['key_obligations'] ?? []),
        keyRights: List<String>.from(json['key_rights'] ?? []),
      );
}

// ─── Risk ─────────────────────────────────────────────────────────────────────

class RedFlag {
  final String flagType;
  final String description;
  final String extractedText;
  final String severity;
  final int? pageReference;

  RedFlag({
    required this.flagType,
    required this.description,
    required this.extractedText,
    required this.severity,
    this.pageReference,
  });

  factory RedFlag.fromJson(Map<String, dynamic> json) => RedFlag(
        flagType: json['flag_type'],
        description: json['description'],
        extractedText: json['extracted_text'],
        severity: json['severity'],
        pageReference: json['page_reference'],
      );
}

class RiskAnalysis {
  final String documentId;
  final int riskScore;
  final String riskLevel;
  final List<RedFlag> detectedRedFlags;
  final String riskSummary;

  RiskAnalysis({
    required this.documentId,
    required this.riskScore,
    required this.riskLevel,
    required this.detectedRedFlags,
    required this.riskSummary,
  });

  factory RiskAnalysis.fromJson(Map<String, dynamic> json) => RiskAnalysis(
        documentId: json['document_id'],
        riskScore: json['risk_score'],
        riskLevel: json['risk_level'],
        detectedRedFlags:
            (json['detected_red_flags'] as List).map((e) => RedFlag.fromJson(e)).toList(),
        riskSummary: json['risk_summary'],
      );
}

// ─── Fairness ─────────────────────────────────────────────────────────────────

class ClauseFairnessItem {
  final String clauseType;
  final String contractValue;
  final String typicalStandard;
  final String fairnessRating;
  final String aiInsight;
  final String? severity;

  ClauseFairnessItem({
    required this.clauseType,
    required this.contractValue,
    required this.typicalStandard,
    required this.fairnessRating,
    required this.aiInsight,
    this.severity,
  });

  factory ClauseFairnessItem.fromJson(Map<String, dynamic> json) => ClauseFairnessItem(
        clauseType: json['clause_type'],
        contractValue: json['contract_value'],
        typicalStandard: json['typical_standard'],
        fairnessRating: json['fairness_rating'],
        aiInsight: json['ai_insight'],
        severity: json['severity'],
      );
}

class ClauseFairness {
  final String documentId;
  final String overallFairness;
  final List<ClauseFairnessItem> clausesAnalyzed;

  ClauseFairness({
    required this.documentId,
    required this.overallFairness,
    required this.clausesAnalyzed,
  });

  factory ClauseFairness.fromJson(Map<String, dynamic> json) => ClauseFairness(
        documentId: json['document_id'],
        overallFairness: json['overall_fairness'],
        clausesAnalyzed: (json['clauses_analyzed'] as List)
            .map((e) => ClauseFairnessItem.fromJson(e))
            .toList(),
      );
}

// ─── Safety Score ─────────────────────────────────────────────────────────────

class SafetyScore {
  final String documentId;
  final int safetyScore;
  final String riskLevel;
  final Map<String, dynamic> scoreBreakdown;
  final List<String> recommendations;

  SafetyScore({
    required this.documentId,
    required this.safetyScore,
    required this.riskLevel,
    required this.scoreBreakdown,
    required this.recommendations,
  });

  factory SafetyScore.fromJson(Map<String, dynamic> json) => SafetyScore(
        documentId: json['document_id'],
        safetyScore: json['safety_score'],
        riskLevel: json['risk_level'],
        scoreBreakdown: json['score_breakdown'],
        recommendations: List<String>.from(json['recommendations'] ?? []),
      );
}

// ─── Chat ─────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ChatResponse {
  final String aiResponse;
  final List<String> sourceChunks;

  ChatResponse({required this.aiResponse, required this.sourceChunks});

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
        aiResponse: json['ai_response'],
        sourceChunks: List<String>.from(json['source_chunks'] ?? []),
      );
}

class LegalChatResponse {
  final String aiResponse;
  final String disclaimer;

  LegalChatResponse({required this.aiResponse, required this.disclaimer});

  factory LegalChatResponse.fromJson(Map<String, dynamic> json) => LegalChatResponse(
        aiResponse: json['ai_response'],
        disclaimer: json['disclaimer'],
      );
}

// ─── Guidance ─────────────────────────────────────────────────────────────────

class DocumentStep {
  final int stepNumber;
  final String title;
  final String description;

  DocumentStep({required this.stepNumber, required this.title, required this.description});

  factory DocumentStep.fromJson(Map<String, dynamic> json) => DocumentStep(
        stepNumber: json['step_number'],
        title: json['title'],
        description: json['description'],
      );
}

class RequiredDocumentItem {
  final String documentName;
  final String description;
  final String whereToObtain;
  final List<DocumentStep> steps;
  final String? validity;
  final String? notes;

  RequiredDocumentItem({
    required this.documentName,
    required this.description,
    required this.whereToObtain,
    required this.steps,
    this.validity,
    this.notes,
  });

  factory RequiredDocumentItem.fromJson(Map<String, dynamic> json) => RequiredDocumentItem(
        documentName: json['document_name'],
        description: json['description'],
        whereToObtain: json['where_to_obtain'],
        steps: (json['steps'] as List).map((e) => DocumentStep.fromJson(e)).toList(),
        validity: json['validity'],
        notes: json['notes'],
      );
}

class GuidanceResponse {
  final String category;
  final String processName;
  final String overview;
  final List<RequiredDocumentItem> requiredDocuments;
  final List<String> generalTips;

  GuidanceResponse({
    required this.category,
    required this.processName,
    required this.overview,
    required this.requiredDocuments,
    required this.generalTips,
  });

  factory GuidanceResponse.fromJson(Map<String, dynamic> json) => GuidanceResponse(
        category: json['category'],
        processName: json['process_name'],
        overview: json['overview'],
        requiredDocuments: (json['required_documents'] as List)
            .map((e) => RequiredDocumentItem.fromJson(e))
            .toList(),
        generalTips: List<String>.from(json['general_tips'] ?? []),
      );
}
