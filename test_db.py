import sys
import os
from dotenv import load_dotenv

load_dotenv(r"C:\Users\gonza\asthma-api\.env")
os.environ["SUPABASE_SERVICE_ROLE_KEY"] = "mock_key_just_to_pass_validation"

sys.path.append(r"C:\Users\gonza\asthma-api")

from app.config.database import SessionLocal
from app.infrastructure.models.user import User
from app.infrastructure.models.action_plan import ActionPlan
from app.infrastructure.models.action_step import ActionStep
from app.infrastructure.models.medication import Medication

try:
    db = SessionLocal()
    last_user = db.query(User).order_by(User.id.desc()).first()
    print(f"User check: {last_user.email} (ID: {last_user.id})")
    
    meds = db.query(Medication).order_by(Medication.id.desc()).limit(10).all()
    print(f"--- ÚLTIMOS MEDICAMENTOS ---")
    for m in meds:
        print(f"ID: {m.id}, User_ID: {m.user_id}, Name: {m.name}, is_active: {m.is_active}")

    plans = db.query(ActionPlan).order_by(ActionPlan.id.desc()).limit(10).all()
    print(f"\n--- ÚLTIMOS PLANES DE ACCIÓN ---")
    for p in plans:
        steps = db.query(ActionStep).filter(ActionStep.action_plan_id == p.id).all()
        print(f"ID: {p.id}, User_ID: {p.user_id}, Name: {p.plan_name}, is_active: {p.is_active}, Steps: {len(steps)}")
        
except Exception as e:
    print("ERROR:", e)
