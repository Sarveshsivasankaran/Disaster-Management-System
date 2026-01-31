import time
import feedparser
from datetime import datetime, timezone
from supabase_client import insert_news_alert

# -------------------------------------------------
# INDIA-ONLY RSS SOURCES (NO GLOBAL FEEDS)
# -------------------------------------------------
RSS_SOURCES = [
    {"name": "The Hindu – Tamil Nadu", "url": "https://www.thehindu.com/news/national/tamil-nadu/feeder/default.rss"},
    {"name": "The Hindu – Kerala", "url": "https://www.thehindu.com/news/national/kerala/feeder/default.rss"},
    {"name": "The Hindu – Karnataka", "url": "https://www.thehindu.com/news/national/karnataka/feeder/default.rss"},
    {"name": "The Hindu – Andhra Pradesh", "url": "https://www.thehindu.com/news/national/andhra-pradesh/feeder/default.rss"},
    {"name": "The Hindu – Telangana", "url": "https://www.thehindu.com/news/national/telangana/feeder/default.rss"},
    {"name": "NDTV – India", "url": "https://feeds.feedburner.com/ndtvnews-india-news"}
]

# -------------------------------------------------
# HARD BLOCKLIST (FOREIGN LOCATIONS)
# -------------------------------------------------
FOREIGN_BLOCK_KEYWORDS = [
    # Americas
    "united states", "usa", "new jersey", "new york", "california",
    "texas", "nevada", "alaska", "canada", "mexico",

    # Europe
    "uk", "england", "france", "germany", "italy", "spain",
    "russia", "ukraine",

    # Asia (non-India)
    "china", "japan", "indonesia", "philippines", "pakistan",
    "afghanistan", "nepal", "sri lanka", "bangladesh",

    # Middle East & others
    "iran", "iraq", "israel", "turkey", "syria",
    "australia", "new zealand", "africa""mitkat",
    "risk analysis",
    "advisory services"
]

# -------------------------------------------------
# SOUTH INDIA LOCATION KEYWORDS (VERY EXTENSIVE)
# -------------------------------------------------
SOUTH_INDIA_KEYWORDS = [
    # States
    "tamil nadu", "kerala", "karnataka", "andhra pradesh", "telangana",

    # Tamil Nadu
    "chennai", "coimbatore", "madurai", "salem", "erode", "tiruppur",
    "vellore", "ranipet", "tiruvallur", "kanchipuram", "chengalpattu",
    "thanjavur", "tiruvarur", "nagapattinam", "cuddalore",
    "tirunelveli", "thoothukudi", "kanyakumari", "virudhunagar",
    "dindigul", "karur", "namakkal", "krishnagiri", "dharmapuri",
    "nilgiris", "ooty",

    # Kerala
    "kochi", "ernakulam", "thiruvananthapuram", "trivandrum",
    "kozhikode", "calicut", "thrissur", "palakkad", "alappuzha",
    "kottayam", "idukki", "wayanad", "kannur", "kasaragod",
    "malappuram", "pathanamthitta",

    # Karnataka
    "bengaluru", "bangalore", "mysuru", "mysore", "mandya",
    "mangalore", "udupi", "chikkamagaluru", "shivamogga",
    "davanagere", "tumakuru", "ballari", "raichur", "kalaburagi",
    "hubballi", "dharwad", "belagavi", "kodagu", "coorg",

    # Andhra Pradesh
    "visakhapatnam", "vizag", "vijayawada", "guntur", "nellore",
    "tirupati", "chittoor", "kurnool", "ananthapur", "kadapa",
    "srikakulam", "vizianagaram", "east godavari", "west godavari",

    # Telangana
    "hyderabad", "secunderabad", "warangal", "karimnagar",
    "nizamabad", "adilabad", "khammam", "mahbubnagar",
    "nalgonda", "medak",

    # Regions
    "south india", "western ghats", "deccan plateau",
    "coromandel coast", "konkan coast"
]

# -------------------------------------------------
# DISASTER KEYWORDS (VERY EXTENSIVE)
# -------------------------------------------------
DISASTER_KEYWORDS = [
    "flood", "floods", "flooding", "flash flood", "urban flooding",
    "waterlogging", "inundation", "river overflow", "dam overflow",
    "reservoir overflow", "breach",

    "heavy rain", "heavy rains", "heavy rainfall",
    "very heavy rainfall", "extremely heavy rainfall",
    "cloudburst", "monsoon", "southwest monsoon", "northeast monsoon",

    "cyclone", "cyclonic storm", "severe cyclonic storm",
    "depression", "deep depression", "low pressure area",
    "gale winds", "storm surge", "rough sea",

    "landslide", "landslides", "mudslide", "slope failure",
    "rockfall", "soil erosion",

    "earthquake", "tremor", "seismic activity",

    "heatwave", "heat wave", "extreme heat", "drought",
    "water scarcity",

    "evacuation", "evacuated", "relief camp", "shelter camp",
    "rescue operation", "rescue teams", "ndrf", "sdrf",
    "army deployed", "air force rescue",

    "imd warning", "imd alert", "red alert",
    "orange alert", "yellow alert", "weather warning",

    "casualties", "loss of life", "houses damaged",
    "roads submerged", "bridge collapse",
    "power outage", "communication disrupted"
]

# -------------------------------------------------
# HELPER
# -------------------------------------------------
def contains_keyword(text, keywords):
    text = text.lower()
    return any(word in text for word in keywords)

# -------------------------------------------------
# INGEST ONE CYCLE
# -------------------------------------------------
def ingest_once():
    print("🔄 Fetching South India disaster news...")

    for source in RSS_SOURCES:
        feed = feedparser.parse(source["url"])

        for entry in feed.entries[:20]:
            title = entry.get("title", "")
            summary = entry.get("summary", "")
            combined = f"{title} {summary}"

            # ❌ HARD BLOCK FOREIGN NEWS
            if contains_keyword(combined, FOREIGN_BLOCK_KEYWORDS):
                continue

            # ✅ MUST BE SOUTH INDIA
            if not contains_keyword(combined, SOUTH_INDIA_KEYWORDS):
                continue

            # ✅ MUST BE DISASTER
            if not contains_keyword(combined, DISASTER_KEYWORDS):
                continue

            # Extra safety for earthquakes
            if ("earthquake" in combined.lower() or "seismic" in combined.lower()) \
               and not contains_keyword(combined, SOUTH_INDIA_KEYWORDS):
                continue

            news = {
                "title": title[:180],
                "message": summary[:400],
                "source": source["name"],
                "region": "South India",
                "alert_type": "news",
                "severity": "warning",
                "verified": True,
                "confidence": 92,
                "created_at": datetime.now(timezone.utc).isoformat()
            }

            insert_news_alert(news)

    print("✅ Cycle complete\n")

# -------------------------------------------------
# AUTO RUN EVERY 30 SECONDS
# -------------------------------------------------
def start(interval=30):
    print(f"🚀 South India disaster monitor running every {interval}s")
    while True:
        try:
            ingest_once()
            time.sleep(interval)
        except Exception as e:
            print("❌ Error:", e)
            time.sleep(interval)

if __name__ == "__main__":
    start(30)
