// ─── Auth ──────────────────────────────────────────────────────────────────────

class AuthResponse {
  final String userId;
  final String name;
  final String email;
  final String token;
  final String message;

  AuthResponse({
    required this.userId,
    required this.name,
    required this.email,
    required this.token,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        userId: json['user_id'],
        name: json['name'],
        email: json['email'],
        token: json['token'],
        message: json['message'] ?? '',
      );
}

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final int documentsCount;
  final String createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.documentsCount,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['user_id'],
        name: json['name'],
        email: json['email'],
        documentsCount: json['documents_count'] ?? 0,
        createdAt: json['created_at'] ?? '',
      );
}

class DocumentHistoryItem {
  final String documentId;
  final String filename;
  final String? docType;
  final String uploadedAt;
  final Map<String, dynamic> analysis;

  DocumentHistoryItem({
    required this.documentId,
    required this.filename,
    this.docType,
    required this.uploadedAt,
    required this.analysis,
  });

  factory DocumentHistoryItem.fromJson(Map<String, dynamic> json) =>
      DocumentHistoryItem(
        documentId: json['document_id'],
        filename: json['filename'],
        docType: json['doc_type'],
        uploadedAt: json['uploaded_at'] ?? '',
        analysis: Map<String, dynamic>.from(json['analysis'] ?? {}),
      );
}

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
  final String role;
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

// ─── Feature A: Contract Safety Comparison ────────────────────────────────────

class ClauseComparison {
  final String clauseType;
  final String contractAText;
  final String contractBText;
  final String winner;     // "A" | "B" | "tie"
  final String outcome;    // "better" | "worse" | "similar"
  final String reason;
  final String severity;

  ClauseComparison({
    required this.clauseType,
    required this.contractAText,
    required this.contractBText,
    required this.winner,
    required this.outcome,
    required this.reason,
    required this.severity,
  });

  factory ClauseComparison.fromJson(Map<String, dynamic> json) => ClauseComparison(
        clauseType: json['clause_type'] ?? '',
        contractAText: json['contract_a_text'] ?? '',
        contractBText: json['contract_b_text'] ?? '',
        winner: json['winner'] ?? 'tie',
        outcome: json['outcome'] ?? 'similar',
        reason: json['reason'] ?? '',
        severity: json['severity'] ?? 'medium',
      );
}

class ContractComparison {
  final int contractASafetyScore;
  final int contractBSafetyScore;
  final String winner;
  final int percentageDifference;
  final String verdict;
  final List<String> keyDifferences;
  final List<ClauseComparison> clauseComparisons;
  final String filenameA;
  final String filenameB;

  ContractComparison({
    required this.contractASafetyScore,
    required this.contractBSafetyScore,
    required this.winner,
    required this.percentageDifference,
    required this.verdict,
    required this.keyDifferences,
    required this.clauseComparisons,
    required this.filenameA,
    required this.filenameB,
  });

  factory ContractComparison.fromJson(Map<String, dynamic> json) => ContractComparison(
        contractASafetyScore: json['contract_a_safety_score'] ?? 0,
        contractBSafetyScore: json['contract_b_safety_score'] ?? 0,
        winner: json['winner'] ?? 'tie',
        percentageDifference: json['percentage_difference'] ?? 0,
        verdict: json['verdict'] ?? '',
        keyDifferences: List<String>.from(json['key_differences'] ?? []),
        clauseComparisons: (json['clause_comparisons'] as List? ?? [])
            .map((e) => ClauseComparison.fromJson(e))
            .toList(),
        filenameA: json['filename_a'] ?? 'Contract A',
        filenameB: json['filename_b'] ?? 'Contract B',
      );
}

// ─── Feature B: Clause Rewriting ──────────────────────────────────────────────

class RewriteSuggestion {
  final String clauseType;
  final String originalText;
  final String riskReason;
  final String riskLevel;
  final String suggestedRewrite;
  final String negotiationTip;
  final String whatToDoIfRefused;

  RewriteSuggestion({
    required this.clauseType,
    required this.originalText,
    required this.riskReason,
    required this.riskLevel,
    required this.suggestedRewrite,
    required this.negotiationTip,
    required this.whatToDoIfRefused,
  });

  factory RewriteSuggestion.fromJson(Map<String, dynamic> json) => RewriteSuggestion(
        clauseType: json['clause_type'] ?? '',
        originalText: json['original_text'] ?? '',
        riskReason: json['risk_reason'] ?? '',
        riskLevel: json['risk_level'] ?? 'medium',
        suggestedRewrite: json['suggested_rewrite'] ?? '',
        negotiationTip: json['negotiation_tip'] ?? '',
        whatToDoIfRefused: json['what_to_do_if_refused'] ?? '',
      );
}

class RewriteResult {
  final String documentId;
  final String tone;
  final String overallAssessment;
  final int totalRiskyClauses;
  final String rewriteDifficulty;
  final List<RewriteSuggestion> suggestions;

  RewriteResult({
    required this.documentId,
    required this.tone,
    required this.overallAssessment,
    required this.totalRiskyClauses,
    required this.rewriteDifficulty,
    required this.suggestions,
  });

  factory RewriteResult.fromJson(Map<String, dynamic> json) => RewriteResult(
        documentId: json['document_id'] ?? '',
        tone: json['tone'] ?? 'standard',
        overallAssessment: json['overall_assessment'] ?? '',
        totalRiskyClauses: json['total_risky_clauses'] ?? 0,
        rewriteDifficulty: json['rewrite_difficulty'] ?? 'Unknown',
        suggestions: (json['suggestions'] as List? ?? [])
            .map((e) => RewriteSuggestion.fromJson(e))
            .toList(),
      );
}

// ─── Feature C: Smart Checklist ───────────────────────────────────────────────

class ChecklistItem {
  final String item;
  final String status; // "present" | "missing" | "warning"
  final String explanation;
  final String? action;

  ChecklistItem({
    required this.item,
    required this.status,
    required this.explanation,
    this.action,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        item: json['item'] ?? '',
        status: json['status'] ?? 'missing',
        explanation: json['explanation'] ?? '',
        action: json['action'],
      );
}

class SmartChecklist {
  final String documentId;
  final String documentType;
  final int checklistScore;
  final String summary;
  final List<ChecklistItem> items;

  SmartChecklist({
    required this.documentId,
    required this.documentType,
    required this.checklistScore,
    required this.summary,
    required this.items,
  });

  factory SmartChecklist.fromJson(Map<String, dynamic> json) => SmartChecklist(
        documentId: json['document_id'] ?? '',
        documentType: json['document_type'] ?? '',
        checklistScore: json['checklist_score'] ?? 0,
        summary: json['summary'] ?? '',
        items: (json['items'] as List? ?? [])
            .map((e) => ChecklistItem.fromJson(e))
            .toList(),
      );
}

// ─── Feature D: Version Diff ──────────────────────────────────────────────────

class ContractChange {
  final String clauseType;
  final String changeType;      // "added" | "removed" | "modified"
  final String v1Text;
  final String v2Text;
  final String favorability;    // "more_favorable" | "less_favorable" | "neutral"
  final String impact;          // "high" | "medium" | "low"
  final String plainExplanation;

  ContractChange({
    required this.clauseType,
    required this.changeType,
    required this.v1Text,
    required this.v2Text,
    required this.favorability,
    required this.impact,
    required this.plainExplanation,
  });

  factory ContractChange.fromJson(Map<String, dynamic> json) => ContractChange(
        clauseType: json['clause_type'] ?? '',
        changeType: json['change_type'] ?? 'modified',
        v1Text: json['v1_text'] ?? '',
        v2Text: json['v2_text'] ?? '',
        favorability: json['favorability'] ?? 'neutral',
        impact: json['impact'] ?? 'medium',
        plainExplanation: json['plain_explanation'] ?? '',
      );
}

class VersionDiff {
  final String overallVerdict;  // "significantly_better" | "slightly_better" | "neutral" | "slightly_worse" | "significantly_worse"
  final String summary;
  final int favorableChanges;
  final int unfavorableChanges;
  final List<String> newRestrictionsAdded;
  final List<String> rightsRemoved;
  final List<ContractChange> changes;
  final String filenameV1;
  final String filenameV2;

  VersionDiff({
    required this.overallVerdict,
    required this.summary,
    required this.favorableChanges,
    required this.unfavorableChanges,
    required this.newRestrictionsAdded,
    required this.rightsRemoved,
    required this.changes,
    required this.filenameV1,
    required this.filenameV2,
  });

  factory VersionDiff.fromJson(Map<String, dynamic> json) => VersionDiff(
        overallVerdict: json['overall_verdict'] ?? 'neutral',
        summary: json['summary'] ?? '',
        favorableChanges: json['favorable_changes'] ?? 0,
        unfavorableChanges: json['unfavorable_changes'] ?? 0,
        newRestrictionsAdded: List<String>.from(json['new_restrictions_added'] ?? []),
        rightsRemoved: List<String>.from(json['rights_removed'] ?? []),
        changes: (json['changes'] as List? ?? [])
            .map((e) => ContractChange.fromJson(e))
            .toList(),
        filenameV1: json['filename_v1'] ?? 'Version 1',
        filenameV2: json['filename_v2'] ?? 'Version 2',
      );
}