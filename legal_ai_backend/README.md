# 🏛️ Legal AI Backend

> AI-Powered Legal Document Simplification and Guidance System

A complete FastAPI backend for a Flutter mobile application that helps users understand,
analyze, and interact with legal documents using local LLMs via Ollama.

---

## 📋 Features

| Feature | Endpoint | Description |
|---|---|---|
| Document Upload | `POST /api/v1/upload-document` | PDF, DOCX, image upload with OCR |
| AI Summary | `GET /api/v1/document-summary/{id}` | Plain-language summaries (3 modes) |
| Risk Analysis | `GET /api/v1/risk-analysis/{id}` | Red flag and risk detection |
| Clause Fairness | `GET /api/v1/clause-fairness/{id}` | Compare vs. industry benchmarks |
| Safety Score | `GET /api/v1/safety-score/{id}` | Overall contract safety (0–100) |
| RAG Chat | `POST /api/v1/chat-with-document` | Ask questions about the document |
| Docs Guidance | `GET /api/v1/required-documents/{category}` | Required docs for legal processes |
| Legal Chatbot | `POST /api/v1/legal-chat` | General AI legal Q&A |
| Translation | `POST /api/v1/translate-response` | Multilingual support |

---

## 🏗️ Project Structure

```
legal_ai_backend/
├── main.py                        # FastAPI app entry point
├── requirements.txt
├── .env.example                   # Environment configuration
│
├── config/
│   └── settings.py                # Pydantic Settings
│
├── core/
│   ├── document_parser.py         # PDF/DOCX/Image parser + OCR
│   ├── embeddings.py              # Sentence-Transformers
│   ├── vector_store.py            # ChromaDB operations
│   └── llm_client.py              # Ollama async client
│
├── api/
│   └── routes/
│       ├── documents.py           # Document analyzer routes
│       ├── guidance.py            # Required documents routes
│       ├── chatbot.py             # Legal chatbot route
│       └── translation.py        # Translation route
│
├── models/
│   └── schemas.py                 # All Pydantic request/response schemas
│
├── services/
│   ├── document_service.py        # Upload + summary logic
│   ├── risk_service.py            # Risk detection
│   ├── fairness_service.py        # Clause benchmarking
│   ├── chat_service.py            # RAG chat + safety score
│   ├── chatbot_service.py         # General legal chatbot
│   ├── guidance_service.py        # Guidance knowledge base
│   └── translation_service.py    # Deep-translator wrapper
│
├── data/
│   └── knowledge_base.py          # Required documents knowledge base
│
├── utils/
│   ├── logging.py                 # Loguru setup
│   └── helpers.py                 # Chunking, scoring, utilities
│
└── storage/
    ├── documents/                 # Uploaded files (auto-created)
    └── chroma_db/                 # ChromaDB persistence (auto-created)
```

---

## ⚙️ Prerequisites

### System Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install tesseract-ocr tesseract-ocr-eng

# macOS
brew install tesseract

# Windows
# Download from: https://github.com/UB-Mannheim/tesseract/wiki
```

### Ollama (Local LLM)

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull a model (choose one)
ollama pull llama3      # Recommended (8B, ~4.7GB)
ollama pull mistral     # Alternative (7B, ~4.1GB)

# Start Ollama server
ollama serve
```

---

## 🚀 Installation

```bash
# 1. Clone the repository
git clone <repo-url>
cd legal_ai_backend

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
cp .env.example .env
# Edit .env to customize settings

# 5. Start the server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 📖 API Documentation

Once running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

---

## 🔌 Flutter Integration

### Base URL
```dart
const String baseUrl = 'http://YOUR_SERVER_IP:8000/api/v1';
```

### Upload Document
```dart
// POST /api/v1/upload-document
var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-document'));
request.files.add(await http.MultipartFile.fromPath('file', filePath));
var response = await request.send();
// Returns: { document_id, filename, number_of_pages, status }
```

### Get Summary
```dart
// GET /api/v1/document-summary/{id}?mode=beginner
final response = await http.get(
  Uri.parse('$baseUrl/document-summary/$documentId?mode=beginner'),
);
```

### Risk Analysis
```dart
// GET /api/v1/risk-analysis/{id}
final response = await http.get(Uri.parse('$baseUrl/risk-analysis/$documentId'));
```

### Chat With Document
```dart
// POST /api/v1/chat-with-document
final response = await http.post(
  Uri.parse('$baseUrl/chat-with-document'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'document_id': documentId,
    'user_question': 'What is the notice period?',
    'conversation_history': [],
  }),
);
```

### Legal Chatbot
```dart
// POST /api/v1/legal-chat
final response = await http.post(
  Uri.parse('$baseUrl/legal-chat'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'user_message': 'What is a non-compete clause?',
    'conversation_history': [],
    'language': 'Hindi',
  }),
);
```

---

## 🌍 Supported Languages (Translation)

| Language | Code |
|---|---|
| English | en |
| Hindi | hi |
| Marathi | mr |
| Spanish | es |
| French | fr |
| German | de |
| Arabic | ar |
| Chinese | zh-CN |
| Japanese | ja |
| Portuguese | pt |

---

## 📚 Document Guidance Categories

| Category | Covers |
|---|---|
| `housing` | Rental, property purchase, lease |
| `loan` | Home loan, personal loan, car loan |
| `employment` | Job offers, NDAs, employment contracts |
| `business` | GST, partnerships, vendor agreements |
| `education` | Admissions, scholarships, internships |
| `insurance` | Health, life, car insurance |
| `digital` | Terms of service, privacy policies, EULAs |
| `personal` | Wills, power of attorney, affidavits |

---

## 🔒 Security Notes

- Change `allow_origins=["*"]` to specific Flutter app origins in production
- Add API key authentication middleware for production deployment
- Store uploaded files in cloud storage (S3/GCS) for multi-instance deployment
- Use Redis for the document registry in production (replace in-memory dict)
- Enable HTTPS in production deployments

---

## 🧠 System Architecture

```
Flutter Mobile App
        ↓
  FastAPI Backend (port 8000)
        ↓
  ┌─────────────────────────────┐
  │    Document Parser Layer    │
  │  (PyPDF + pdfplumber + OCR) │
  └──────────────┬──────────────┘
                 ↓
  ┌─────────────────────────────┐
  │    Embeddings Layer         │
  │  (sentence-transformers)    │
  └──────────────┬──────────────┘
                 ↓
  ┌─────────────────────────────┐
  │    ChromaDB Vector Store    │
  │  (persistent similarity DB) │
  └──────────────┬──────────────┘
                 ↓
  ┌─────────────────────────────┐
  │    Ollama LLM               │
  │  (Llama3 / Mistral)         │
  └──────────────┬──────────────┘
                 ↓
         JSON API Response
```

---

## 📝 License

MIT License — use freely for educational and commercial projects.
