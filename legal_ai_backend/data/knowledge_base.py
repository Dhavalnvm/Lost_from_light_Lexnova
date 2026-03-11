"""
Structured knowledge base for required documents across different legal categories.
"""

KNOWLEDGE_BASE = {
    "housing": {
        "process_name": "Housing & Property",
        "overview": (
            "Property and housing transactions require specific documents to protect all parties. "
            "Whether renting, buying, or leasing, having the right documents ensures legal protection."
        ),
        "required_documents": [
            {
                "document_name": "Aadhaar Card",
                "description": "Government-issued unique identity card with biometric data",
                "where_to_obtain": "UIDAI website (uidai.gov.in) or nearest Aadhaar enrollment center",
                "validity": "Lifetime",
                "notes": "Both physical and e-Aadhaar are accepted",
                "steps": [
                    {"step_number": 1, "title": "Visit enrollment center", "description": "Locate the nearest Aadhaar enrollment center via uidai.gov.in"},
                    {"step_number": 2, "title": "Fill enrollment form", "description": "Complete the Aadhaar enrollment form with personal details"},
                    {"step_number": 3, "title": "Biometric scan", "description": "Provide fingerprints and iris scan at the enrollment center"},
                    {"step_number": 4, "title": "Receive Aadhaar", "description": "Aadhaar card delivered by post within 90 days; download e-Aadhaar from UIDAI portal"},
                ],
            },
            {
                "document_name": "PAN Card",
                "description": "Permanent Account Number card issued by Income Tax Department",
                "where_to_obtain": "NSDL or UTIITSL portal online, or through TIN facilitation centers",
                "validity": "Lifetime",
                "notes": "Mandatory for property transactions above ₹5 lakhs",
                "steps": [
                    {"step_number": 1, "title": "Apply online", "description": "Visit NSDL (tin-nsdl.com) or UTIITSL portal and fill Form 49A"},
                    {"step_number": 2, "title": "Upload documents", "description": "Upload identity proof, address proof, and date of birth proof"},
                    {"step_number": 3, "title": "Pay fee", "description": "Pay the application fee (approx ₹107 for Indian address delivery)"},
                    {"step_number": 4, "title": "Receive PAN", "description": "PAN card delivered within 15 working days"},
                ],
            },
            {
                "document_name": "Rental Agreement / Lease Agreement",
                "description": "Legal contract between landlord and tenant specifying terms of tenancy",
                "where_to_obtain": "Draft with a lawyer or use online legal platforms; register at Sub-Registrar office",
                "validity": "Per agreement (typically 11 months to 3 years)",
                "notes": "Must be registered if duration exceeds 11 months",
                "steps": [
                    {"step_number": 1, "title": "Draft agreement", "description": "Include rent amount, duration, deposit, maintenance, and termination terms"},
                    {"step_number": 2, "title": "Print on stamp paper", "description": "Print on non-judicial stamp paper of required value (varies by state)"},
                    {"step_number": 3, "title": "Sign with witnesses", "description": "Both parties sign in presence of two witnesses"},
                    {"step_number": 4, "title": "Register if needed", "description": "Register at Sub-Registrar office if tenure exceeds 11 months"},
                ],
            },
            {
                "document_name": "Bank Statements",
                "description": "Last 6 months bank statements showing financial transactions",
                "where_to_obtain": "Your bank branch, net banking portal, or bank app",
                "validity": "Usually last 6 months required",
                "notes": "Must be official bank-stamped or certified statements",
                "steps": [
                    {"step_number": 1, "title": "Log in to bank portal", "description": "Access your internet banking portal or visit the bank"},
                    {"step_number": 2, "title": "Download statements", "description": "Download last 6 months statements in PDF format"},
                    {"step_number": 3, "title": "Get attestation if needed", "description": "For physical submission, get statements stamped and signed at branch"},
                ],
            },
            {
                "document_name": "No Objection Certificate (NOC)",
                "description": "Certificate from housing society or building authority permitting rental/sale",
                "where_to_obtain": "Housing society office or building management",
                "validity": "Typically 3–6 months",
                "notes": "Required for sub-letting or in co-operative housing societies",
                "steps": [
                    {"step_number": 1, "title": "Write application", "description": "Draft a formal application to the society requesting NOC"},
                    {"step_number": 2, "title": "Submit to society", "description": "Submit with details of new tenant/buyer and intended use"},
                    {"step_number": 3, "title": "Await approval", "description": "Society reviews and issues NOC within 15–30 days"},
                ],
            },
        ],
        "general_tips": [
            "Always register agreements lasting more than 11 months to ensure legal protection",
            "Keep copies of all documents in both digital and physical form",
            "Verify property ownership via Encumbrance Certificate before any transaction",
            "Check for pending dues on property (electricity, maintenance) before signing",
            "Insist on original document verification, not just photocopies",
        ],
    },
    "loan": {
        "process_name": "Loan & Financial Agreements",
        "overview": (
            "Applying for a loan requires thorough documentation to verify your identity, "
            "income, and creditworthiness. Proper documentation speeds up approval."
        ),
        "required_documents": [
            {
                "document_name": "Identity Proof",
                "description": "Valid government-issued ID (Aadhaar, PAN, Passport, Voter ID)",
                "where_to_obtain": "Respective government departments",
                "validity": "As per document type",
                "notes": "At least two forms of ID are usually required",
                "steps": [
                    {"step_number": 1, "title": "Gather ID documents", "description": "Collect Aadhaar card and PAN card as primary IDs"},
                    {"step_number": 2, "title": "Make self-attested copies", "description": "Sign 'True Copy' on each photocopy"},
                    {"step_number": 3, "title": "Keep originals ready", "description": "Carry originals for verification at bank/NBFC"},
                ],
            },
            {
                "document_name": "Income Proof / Salary Slips",
                "description": "Documents proving regular income — 3 months salary slips or 2 years ITR for self-employed",
                "where_to_obtain": "Employer HR department or Income Tax e-filing portal",
                "validity": "Last 3 months (salaried); last 2 years (self-employed)",
                "notes": "Self-employed need ITR, audited balance sheet, and P&L statement",
                "steps": [
                    {"step_number": 1, "title": "Request salary slips", "description": "Contact HR or use payroll portal to download last 3 months slips"},
                    {"step_number": 2, "title": "Get Form 16", "description": "Collect Form 16 (TDS certificate) from employer"},
                    {"step_number": 3, "title": "Download ITR", "description": "Download ITR-V acknowledgment from income tax portal"},
                ],
            },
            {
                "document_name": "Bank Statements",
                "description": "Last 6–12 months bank statements of salary account",
                "where_to_obtain": "Bank branch or internet banking",
                "validity": "Last 6–12 months",
                "notes": "Should show consistent salary credits and no EMI defaults",
                "steps": [
                    {"step_number": 1, "title": "Get certified statements", "description": "Download from net banking or get bank-stamped copy"},
                    {"step_number": 2, "title": "Ensure no bounced cheques", "description": "Review statements for any dishonoured cheques"},
                    {"step_number": 3, "title": "Prepare 12-month statement", "description": "For home loans, 12 months is typically required"},
                ],
            },
            {
                "document_name": "Property Documents (for Home Loan)",
                "description": "Sale deed, property tax receipts, building plan approval",
                "where_to_obtain": "Sub-Registrar office, municipal corporation",
                "validity": "Original documents required",
                "notes": "Bank holds original property documents as collateral",
                "steps": [
                    {"step_number": 1, "title": "Obtain sale deed copy", "description": "Get certified copy from Sub-Registrar office"},
                    {"step_number": 2, "title": "Collect property tax receipts", "description": "Get last 3 years property tax payment receipts from municipality"},
                    {"step_number": 3, "title": "Get Encumbrance Certificate", "description": "Apply for EC at Sub-Registrar to verify no liens on property"},
                ],
            },
        ],
        "general_tips": [
            "Check your CIBIL credit score before applying — aim for 750+",
            "Compare loan offers from multiple banks for best interest rates",
            "Read the loan agreement completely, especially prepayment and foreclosure terms",
            "Understand the processing fee, which is typically non-refundable",
            "Ensure EMI does not exceed 40–50% of monthly take-home salary",
        ],
    },
    "employment": {
        "process_name": "Employment & Work Documents",
        "overview": (
            "Employment documents define the terms of your work relationship. "
            "Understanding them protects your rights and sets clear expectations."
        ),
        "required_documents": [
            {
                "document_name": "Offer Letter",
                "description": "Formal letter from employer confirming job offer, role, and compensation",
                "where_to_obtain": "Provided by the employer's HR department",
                "validity": "Typically valid for 30–60 days from issue",
                "notes": "Not legally binding until Employment Contract is signed",
                "steps": [
                    {"step_number": 1, "title": "Review offer carefully", "description": "Check job title, salary, joining date, and location"},
                    {"step_number": 2, "title": "Negotiate if needed", "description": "This is the best time to negotiate salary and benefits"},
                    {"step_number": 3, "title": "Confirm acceptance", "description": "Reply with formal written acceptance within the deadline"},
                ],
            },
            {
                "document_name": "Employment Contract",
                "description": "Legally binding agreement detailing employment terms, duties, and conditions",
                "where_to_obtain": "Provided by employer; review with a lawyer if needed",
                "validity": "Duration of employment",
                "notes": "Carefully review probation period, notice period, and IP clauses",
                "steps": [
                    {"step_number": 1, "title": "Review all clauses", "description": "Read non-compete, confidentiality, IP ownership, and termination clauses"},
                    {"step_number": 2, "title": "Seek clarification", "description": "Ask HR to explain any unclear terms before signing"},
                    {"step_number": 3, "title": "Sign and keep copy", "description": "Sign both copies; keep one signed original for yourself"},
                ],
            },
            {
                "document_name": "Non-Disclosure Agreement (NDA)",
                "description": "Agreement preventing disclosure of confidential company information",
                "where_to_obtain": "Provided by employer",
                "validity": "Usually 1–5 years post-employment",
                "notes": "Understand what 'confidential information' means under the agreement",
                "steps": [
                    {"step_number": 1, "title": "Identify scope", "description": "Understand what information is covered as confidential"},
                    {"step_number": 2, "title": "Check duration", "description": "Note how long the NDA remains effective after leaving the company"},
                    {"step_number": 3, "title": "Note exceptions", "description": "Look for exceptions (public info, prior knowledge, independently developed)"},
                ],
            },
            {
                "document_name": "Relieving Letter / Experience Certificate",
                "description": "Document from previous employer confirming tenure and good standing",
                "where_to_obtain": "HR department of previous employer upon resignation",
                "validity": "Permanent validity",
                "notes": "Essential for background verification at new employer",
                "steps": [
                    {"step_number": 1, "title": "Serve notice period", "description": "Complete the contractual notice period (typically 30–90 days)"},
                    {"step_number": 2, "title": "Request formally", "description": "Submit written request to HR for relieving letter and experience certificate"},
                    {"step_number": 3, "title": "Clear dues", "description": "Return company assets, settle dues to receive full and final settlement"},
                ],
            },
        ],
        "general_tips": [
            "Never sign blank employment contracts — fill all blanks before signing",
            "Ensure both physical and digital copies are maintained",
            "Non-compete clauses that are too broad may not be enforceable — consult a lawyer",
            "Document verbal promises in writing via email before joining",
            "Understand gratuity eligibility (5 years of service in India)",
        ],
    },
    "business": {
        "process_name": "Business Registration & Agreements",
        "overview": (
            "Starting or operating a business requires proper documentation for legal compliance, "
            "partnerships, and commercial relationships."
        ),
        "required_documents": [
            {
                "document_name": "Partnership Agreement",
                "description": "Legal agreement defining roles, profit sharing, and responsibilities among business partners",
                "where_to_obtain": "Draft with a business lawyer; register with Registrar of Firms",
                "validity": "Duration of partnership",
                "notes": "Registered partnership has stronger legal standing",
                "steps": [
                    {"step_number": 1, "title": "Draft agreement", "description": "Include capital contribution, profit ratio, roles, dispute resolution"},
                    {"step_number": 2, "title": "Execute on stamp paper", "description": "Sign on non-judicial stamp paper of required value"},
                    {"step_number": 3, "title": "Register", "description": "Register with Registrar of Firms for legal validity"},
                    {"step_number": 4, "title": "Open business bank account", "description": "Use partnership deed to open a dedicated business account"},
                ],
            },
            {
                "document_name": "GST Registration Certificate",
                "description": "Certificate of registration under Goods and Services Tax",
                "where_to_obtain": "GST portal (gst.gov.in) online",
                "validity": "Valid until cancelled; renewal not required",
                "notes": "Mandatory if annual turnover exceeds ₹20 lakhs (₹10 lakhs for special states)",
                "steps": [
                    {"step_number": 1, "title": "Apply on GST portal", "description": "Fill Form REG-01 on gst.gov.in"},
                    {"step_number": 2, "title": "Upload documents", "description": "Upload PAN, Aadhaar, business address proof, bank details"},
                    {"step_number": 3, "title": "Verification", "description": "GST officer verifies application within 7 working days"},
                    {"step_number": 4, "title": "Receive GSTIN", "description": "Get GST Identification Number upon approval"},
                ],
            },
            {
                "document_name": "Memorandum of Understanding (MOU)",
                "description": "Non-binding agreement outlining intended cooperation between parties",
                "where_to_obtain": "Draft with legal counsel",
                "validity": "Per MOU terms",
                "notes": "MOUs are typically non-binding; convert to a formal contract for binding obligations",
                "steps": [
                    {"step_number": 1, "title": "Define objectives", "description": "Clearly state the purpose and goals of the collaboration"},
                    {"step_number": 2, "title": "Draft terms", "description": "Include roles, responsibilities, timelines, and resource contributions"},
                    {"step_number": 3, "title": "Legal review", "description": "Have a lawyer review to clarify binding vs non-binding clauses"},
                    {"step_number": 4, "title": "Execute", "description": "Both parties sign; notarize if needed"},
                ],
            },
            {
                "document_name": "Vendor / Service Agreement",
                "description": "Contract governing the supply of goods or services between businesses",
                "where_to_obtain": "Draft internally or with legal counsel",
                "validity": "Per agreement terms",
                "notes": "Include SLAs, payment terms, IP rights, and termination clauses",
                "steps": [
                    {"step_number": 1, "title": "Define scope", "description": "Clearly define deliverables, timelines, and acceptance criteria"},
                    {"step_number": 2, "title": "Set payment terms", "description": "Specify payment milestones, late fees, and invoicing process"},
                    {"step_number": 3, "title": "Include IP clauses", "description": "Define who owns the work product created under the agreement"},
                    {"step_number": 4, "title": "Add termination clause", "description": "Include exit provisions for both parties"},
                ],
            },
        ],
        "general_tips": [
            "Register your business entity before entering major contracts",
            "Always have a dedicated lawyer review contracts above ₹5 lakhs",
            "Use clear payment terms with penalties for late payment",
            "Maintain proper records of all signed agreements",
            "Understand tax implications before signing financial agreements",
        ],
    },
    "education": {
        "process_name": "Education & Academic Documents",
        "overview": (
            "Educational institutions require specific documents for admissions, scholarships, "
            "and academic programs. Being prepared speeds up the process."
        ),
        "required_documents": [
            {
                "document_name": "10th & 12th Marksheets",
                "description": "Board examination mark sheets from CBSE, ICSE, or State Board",
                "where_to_obtain": "School/board website or DigiLocker",
                "validity": "Permanent",
                "notes": "Original marksheets required for university admission; DigiLocker copies accepted in many cases",
                "steps": [
                    {"step_number": 1, "title": "Get from school", "description": "Collect original marksheets from school upon board result declaration"},
                    {"step_number": 2, "title": "DigiLocker", "description": "Link Aadhaar to DigiLocker to access digital verified copies"},
                    {"step_number": 3, "title": "Certified copies if lost", "description": "Apply to respective board for duplicate marksheet with fee"},
                ],
            },
            {
                "document_name": "Migration Certificate",
                "description": "Certificate from previous institution allowing joining a new one",
                "where_to_obtain": "Previously attended university/board",
                "validity": "Usually valid for 1 year from issue",
                "notes": "Required when joining a university under a different board/university",
                "steps": [
                    {"step_number": 1, "title": "Apply to previous institution", "description": "Submit written application to registrar/examination office"},
                    {"step_number": 2, "title": "Pay fee", "description": "Pay migration certificate fee (varies by institution)"},
                    {"step_number": 3, "title": "Collect certificate", "description": "Collect within 7–30 days or get delivered by post"},
                ],
            },
            {
                "document_name": "Scholarship Agreement",
                "description": "Legal agreement between student and scholarship provider outlining terms",
                "where_to_obtain": "Scholarship-granting institution",
                "validity": "Per academic year or full program duration",
                "notes": "Understand grade maintenance requirements and repayment conditions if you leave",
                "steps": [
                    {"step_number": 1, "title": "Apply for scholarship", "description": "Submit application with academic records and financial documents"},
                    {"step_number": 2, "title": "Review terms", "description": "Understand GPA requirements, service obligations, and repayment conditions"},
                    {"step_number": 3, "title": "Sign agreement", "description": "Sign and submit agreement; keep a copy"},
                    {"step_number": 4, "title": "Maintain eligibility", "description": "Track academic performance to maintain scholarship eligibility"},
                ],
            },
            {
                "document_name": "Internship Agreement / Offer Letter",
                "description": "Document confirming internship terms, duration, and stipend",
                "where_to_obtain": "Provided by the company/organization offering internship",
                "validity": "Duration of internship",
                "notes": "Unpaid internships may still require an agreement for academic credit",
                "steps": [
                    {"step_number": 1, "title": "Receive offer", "description": "Get formal offer letter with start date, duration, and stipend"},
                    {"step_number": 2, "title": "Confirm with college", "description": "Get college NOC if required for academic credit"},
                    {"step_number": 3, "title": "Sign agreement", "description": "Sign internship agreement and NDA if provided"},
                    {"step_number": 4, "title": "Get completion certificate", "description": "Request internship completion certificate upon finishing"},
                ],
            },
        ],
        "general_tips": [
            "Apply for migration certificates well in advance — processing takes time",
            "Keep academic certificates safe — replacements are time-consuming",
            "Store digital copies in DigiLocker as a backup",
            "Read scholarship terms carefully to avoid repayment surprises",
            "Verify university/institution recognition before signing admission agreements",
        ],
    },
    "insurance": {
        "process_name": "Insurance Documents",
        "overview": (
            "Insurance documents define your coverage, exclusions, and claim procedures. "
            "Understanding your policy ensures you are adequately protected."
        ),
        "required_documents": [
            {
                "document_name": "Health Insurance Policy",
                "description": "Policy document detailing medical coverage, sum insured, and exclusions",
                "where_to_obtain": "Insurance company (LIC, Star Health, ICICI Lombard, etc.)",
                "validity": "1 year; renewable annually",
                "notes": "Check waiting periods for pre-existing diseases (typically 2–4 years)",
                "steps": [
                    {"step_number": 1, "title": "Compare policies", "description": "Use aggregator sites (Policybazaar) to compare coverage and premiums"},
                    {"step_number": 2, "title": "Fill proposal form", "description": "Disclose all medical history accurately to avoid claim rejection"},
                    {"step_number": 3, "title": "Medical examination", "description": "Some insurers require pre-insurance medical tests for older applicants"},
                    {"step_number": 4, "title": "Pay premium", "description": "Pay premium and receive policy document within 7 days"},
                ],
            },
            {
                "document_name": "Life Insurance Policy",
                "description": "Policy providing financial protection to nominees upon policyholder's death",
                "where_to_obtain": "LIC, private insurers, or insurance agents",
                "validity": "Per policy term (10–40 years)",
                "notes": "Nomination is crucial — update nominees after marriage/children",
                "steps": [
                    {"step_number": 1, "title": "Determine coverage need", "description": "Calculate coverage as 10–15x annual income"},
                    {"step_number": 2, "title": "Choose policy type", "description": "Term (pure protection) vs endowment vs ULIP"},
                    {"step_number": 3, "title": "Complete KYC", "description": "Submit identity, address, income proof and medical details"},
                    {"step_number": 4, "title": "Assign nominees", "description": "Clearly name nominees and keep them updated"},
                ],
            },
        ],
        "general_tips": [
            "Read the policy exclusions list carefully — not everything is covered",
            "Pay premiums on time to avoid policy lapse",
            "Update nominee details after major life events",
            "Keep soft and hard copies of all insurance documents",
            "Understand the claim process before you need it",
        ],
    },
    "digital": {
        "process_name": "Digital Agreements & Online Terms",
        "overview": (
            "Digital agreements govern your use of online platforms, apps, and services. "
            "Understanding them protects your data and digital rights."
        ),
        "required_documents": [
            {
                "document_name": "Terms of Service / Terms and Conditions",
                "description": "Legal agreement governing use of a website, app, or digital service",
                "where_to_obtain": "Displayed on the platform website/app",
                "validity": "Until updated by the platform",
                "notes": "Platforms can change terms with notice — check for updates",
                "steps": [
                    {"step_number": 1, "title": "Access terms", "description": "Find Terms of Service in the website footer or app settings"},
                    {"step_number": 2, "title": "Read key sections", "description": "Focus on data usage, account termination, and dispute resolution"},
                    {"step_number": 3, "title": "Check update policy", "description": "Understand how and when the platform notifies you of changes"},
                ],
            },
            {
                "document_name": "Privacy Policy",
                "description": "Document explaining how a platform collects, uses, and shares your personal data",
                "where_to_obtain": "Platform website/app footer",
                "validity": "Until updated",
                "notes": "Under GDPR/DPDP Act, you have rights to access and delete your data",
                "steps": [
                    {"step_number": 1, "title": "Read data collection section", "description": "Understand what personal data is collected"},
                    {"step_number": 2, "title": "Check sharing policy", "description": "Know if data is shared with third parties"},
                    {"step_number": 3, "title": "Know your rights", "description": "Understand how to request data deletion or correction"},
                ],
            },
            {
                "document_name": "End User License Agreement (EULA)",
                "description": "License agreement between software/app developer and end user",
                "where_to_obtain": "Software installation or app download process",
                "validity": "Duration of software use",
                "notes": "You don't own the software — you only have a license to use it",
                "steps": [
                    {"step_number": 1, "title": "Review during installation", "description": "Read EULA during software installation process"},
                    {"step_number": 2, "title": "Note restrictions", "description": "Check restrictions on copying, reverse engineering, and redistribution"},
                    {"step_number": 3, "title": "Understand termination", "description": "Know conditions under which your license can be terminated"},
                ],
            },
        ],
        "general_tips": [
            "Never share personal data with platforms unless absolutely necessary",
            "Regularly review privacy settings on apps you use",
            "Understand arbitration clauses in digital agreements — they waive class action rights",
            "Use opt-out options wherever available for data sharing",
            "Check if the platform operates under Indian law or foreign jurisdiction",
        ],
    },
    "personal": {
        "process_name": "Personal Legal Documents",
        "overview": (
            "Personal legal documents handle family, estate, and individual legal matters. "
            "Having these in order protects you and your loved ones."
        ),
        "required_documents": [
            {
                "document_name": "Will / Testament",
                "description": "Legal document expressing how a person's assets should be distributed after death",
                "where_to_obtain": "Draft with a lawyer; register at Sub-Registrar office",
                "validity": "Until updated or revoked",
                "notes": "A registered will is harder to contest; update after major life changes",
                "steps": [
                    {"step_number": 1, "title": "List all assets", "description": "Document all property, bank accounts, investments, and valuables"},
                    {"step_number": 2, "title": "Appoint executor", "description": "Designate a trusted person to execute the will"},
                    {"step_number": 3, "title": "Draft with lawyer", "description": "Have a lawyer draft the will to ensure it's legally valid"},
                    {"step_number": 4, "title": "Register the will", "description": "Register at Sub-Registrar office with two witnesses for stronger validity"},
                    {"step_number": 5, "title": "Inform executor", "description": "Tell your executor where the will is kept"},
                ],
            },
            {
                "document_name": "Power of Attorney (POA)",
                "description": "Legal document authorizing someone to act on your behalf in legal/financial matters",
                "where_to_obtain": "Draft with a lawyer; notarize or register as required",
                "validity": "Until revoked or specified expiry",
                "notes": "General POA covers all matters; Specific POA is limited to defined acts",
                "steps": [
                    {"step_number": 1, "title": "Choose attorney-in-fact", "description": "Select a trusted person (family member or lawyer)"},
                    {"step_number": 2, "title": "Define scope", "description": "Clearly define what the POA holder can and cannot do"},
                    {"step_number": 3, "title": "Draft and execute", "description": "Draft with a lawyer, sign on stamp paper with witnesses"},
                    {"step_number": 4, "title": "Register if needed", "description": "For property transactions, registration is mandatory"},
                ],
            },
            {
                "document_name": "Affidavit",
                "description": "Written sworn statement of fact, signed before a magistrate or notary",
                "where_to_obtain": "Nearest court, notary public, or High Court premises",
                "validity": "For specific use stated in the affidavit",
                "notes": "Commonly required for name corrections, address proof, declarations",
                "steps": [
                    {"step_number": 1, "title": "Draft statement", "description": "Prepare a clear factual statement of what you are declaring"},
                    {"step_number": 2, "title": "Print on stamp paper", "description": "Print on non-judicial stamp paper of required denomination"},
                    {"step_number": 3, "title": "Swear before notary", "description": "Sign and swear before a notary public or magistrate"},
                    {"step_number": 4, "title": "Get notarized", "description": "Notary stamps and signs the affidavit to certify it"},
                ],
            },
        ],
        "general_tips": [
            "Update your will every 3–5 years or after major life changes",
            "Store originals of critical documents in a fireproof safe",
            "Inform trusted family members about the location of important legal documents",
            "Review POA scope carefully — it can be misused if too broad",
            "Consult a family lawyer for matters involving property and inheritance",
        ],
    },
}


def get_knowledge_base(category: str) -> dict:
    """Return knowledge base entry for a given category."""
    category = category.lower()
    if category not in KNOWLEDGE_BASE:
        raise KeyError(f"Category '{category}' not found. Available: {list(KNOWLEDGE_BASE.keys())}")
    return KNOWLEDGE_BASE[category]


def get_all_categories() -> list:
    return list(KNOWLEDGE_BASE.keys())
