from data.knowledge_base import get_knowledge_base, get_all_categories
from models.schemas import RequiredDocumentsResponse, RequiredDocumentItem, DocumentStep
from utils.logging import app_logger as logger


class GuidanceService:

    def get_required_documents(self, category: str) -> RequiredDocumentsResponse:
        """Retrieve required documents for a given category from the knowledge base."""
        try:
            data = get_knowledge_base(category)
        except KeyError as e:
            raise ValueError(str(e))

        docs = []
        for doc_data in data.get("required_documents", []):
            steps = [
                DocumentStep(
                    step_number=s["step_number"],
                    title=s["title"],
                    description=s["description"],
                )
                for s in doc_data.get("steps", [])
            ]
            docs.append(
                RequiredDocumentItem(
                    document_name=doc_data["document_name"],
                    description=doc_data["description"],
                    where_to_obtain=doc_data["where_to_obtain"],
                    steps=steps,
                    validity=doc_data.get("validity"),
                    notes=doc_data.get("notes"),
                )
            )

        logger.info(f"Returned guidance for category: {category}")

        return RequiredDocumentsResponse(
            category=category,
            process_name=data["process_name"],
            overview=data["overview"],
            required_documents=docs,
            general_tips=data.get("general_tips", []),
        )

    def get_all_categories(self) -> dict:
        return {
            "categories": get_all_categories(),
            "descriptions": {
                "housing": "Rental, property purchase, and housing agreements",
                "loan": "Personal, home, car, and business loans",
                "employment": "Job offers, contracts, NDAs, and work agreements",
                "business": "Partnerships, GST, vendor, and service agreements",
                "education": "Admissions, scholarships, internships, and academic documents",
                "insurance": "Health, life, car, and property insurance",
                "digital": "Online terms, privacy policies, and EULAs",
                "personal": "Wills, POA, affidavits, and personal legal documents",
            },
        }


guidance_service = GuidanceService()
