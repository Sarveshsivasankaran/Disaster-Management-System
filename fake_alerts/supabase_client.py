from supabase import create_client
from dotenv import load_dotenv
import os

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

print("Loaded SUPABASE_URL:", SUPABASE_URL)
print("Loaded SUPABASE_KEY:", "FOUND" if SUPABASE_KEY else None)

if not SUPABASE_URL or not SUPABASE_KEY:
    raise Exception("Supabase credentials not loaded from .env")

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


def insert_news_alert(alert: dict):
    """
    Inserts a single alert record into Supabase alerts table
    """
    response = supabase.table("alerts").insert(alert).execute()
    return response
