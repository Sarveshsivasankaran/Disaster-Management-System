from dotenv import load_dotenv
from pathlib import Path
import os

env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(env_path)

print("URL:", os.getenv("https://nqipgzknhlfsrezssoyr.supabase.co"))
print("KEY:", os.getenv("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xaXBnemtuaGxmc3JlenNzb3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNzQ4ODYsImV4cCI6MjA3Mzk1MDg4Nn0.M1xc6HtScdDjemguonpPgmo8EF0A93OoHvy4LACO24E"))
