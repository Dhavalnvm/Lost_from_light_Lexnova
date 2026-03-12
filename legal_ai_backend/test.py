"""
create_admin.py
---------------
Run this ONCE on your machine to create the admin user + company in MongoDB.

Usage:
    pip install pymongo passlib bcrypt python-jose[cryptography]
    python create_admin.py
"""
import asyncio
from datetime import datetime, timezone, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from jose import jwt
from bson import ObjectId

# ── Config — change these if needed ──────────────────────────────────────────
MONGODB_URI  = "mongodb+srv://nocap7884_db_user:WXNZFlDBR8gUDkiU@cluster0.g7kk8z4.mongodb.net/?appName=Cluster0"
DB_NAME      = "lexnova"
JWT_SECRET   = "lexnova-secret-key-change-in-production-2024"
JWT_ALGO     = "HS256"

# ── Credentials to create ─────────────────────────────────────────────────────
ADMIN_NAME     = "LexNova Admin"
ADMIN_EMAIL    = "admin@lexnova.com"
ADMIN_PASSWORD = "LexNova@2024"
COMPANY_NAME   = "LexNova"
INDUSTRY       = "Legal Technology"
PLAN           = "enterprise"
# ─────────────────────────────────────────────────────────────────────────────

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def create():
    client = AsyncIOMotorClient(MONGODB_URI, serverSelectionTimeoutMS=10000)
    db = client[DB_NAME]

    # ── User ──────────────────────────────────────────────────────────────────
    existing = await db.users.find_one({"email": ADMIN_EMAIL})
    if existing:
        user_id = str(existing["_id"])
        print(f"⚠️  User {ADMIN_EMAIL} already exists (id={user_id}) — updating password")
        await db.users.update_one(
            {"_id": existing["_id"]},
            {"$set": {"password_hash": pwd_context.hash(ADMIN_PASSWORD)}}
        )
    else:
        now = datetime.now(timezone.utc)
        user_doc = {
            "name": ADMIN_NAME,
            "email": ADMIN_EMAIL,
            "password_hash": pwd_context.hash(ADMIN_PASSWORD),
            "created_at": now,
            "documents_count": 0,
        }
        result = await db.users.insert_one(user_doc)
        user_id = str(result.inserted_id)
        print(f"✅ User created: {ADMIN_EMAIL} (id={user_id})")

    # ── Company ───────────────────────────────────────────────────────────────
    now = datetime.now(timezone.utc)
    existing_company = await db.companies.find_one({"owner_user_id": user_id})
    if existing_company:
        company_id = str(existing_company["_id"])
        print(f"⚠️  Company already exists (id={company_id})")
    else:
        company_doc = {
            "name": COMPANY_NAME,
            "industry": INDUSTRY,
            "owner_user_id": user_id,
            "plan": PLAN,
            "created_at": now,
            "billing": {
                "current_plan": "Enterprise",
                "price_usd": 499,
                "next_billing_date": now + timedelta(days=30),
                "monthly_ai_usage": 0,
            },
            "settings": {
                "allow_guest_access": False,
                "two_factor_required": False,
            },
        }
        company_result = await db.companies.insert_one(company_doc)
        company_id = str(company_result.inserted_id)
        print(f"✅ Company created: {COMPANY_NAME} (id={company_id})")

        await db.company_members.insert_one({
            "company_id": company_id,
            "user_id": user_id,
            "role": "admin",
            "joined_at": now,
            "status": "active",
        })
        print(f"✅ Admin member record created")

    # ── Tag user with company ─────────────────────────────────────────────────
    await db.users.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": {"company_id": company_id, "company_role": "admin"}},
    )
    print(f"✅ User tagged with company_id + company_role=admin")

    # ── Generate 30-day token ─────────────────────────────────────────────────
    token = jwt.encode(
        {
            "sub": user_id,
            "email": ADMIN_EMAIL,
            "name": ADMIN_NAME,
            "exp": datetime.now(timezone.utc) + timedelta(days=30),
        },
        JWT_SECRET,
        algorithm=JWT_ALGO,
    )

    print()
    print("=" * 60)
    print("  ✅  ADMIN CREDENTIALS READY")
    print("=" * 60)
    print(f"  Email      : {ADMIN_EMAIL}")
    print(f"  Password   : {ADMIN_PASSWORD}")
    print(f"  User ID    : {user_id}")
    print(f"  Company    : {COMPANY_NAME}")
    print(f"  Company ID : {company_id}")
    print(f"  Plan       : {PLAN}")
    print(f"  Role       : admin")
    print()
    print("  Login via:")
    print("    POST /api/v1/auth/login")
    print('    { "email": "admin@lexnova.com", "password": "LexNova@2024" }')
    print()
    print("  Or use this 30-day token directly:")
    print(f"  {token}")
    print("=" * 60)

    client.close()


if __name__ == "__main__":
    asyncio.run(create())