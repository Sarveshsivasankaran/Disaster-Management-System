# realtime_monitor.py
# Continuous monitoring of live South India disaster news
# Stores ONLY verified alerts into Supabase

import time

from fake_alerts.live_news_feed import fetch_live_disaster_news
from fake_alerts.fake_detector import detect_fake_alert
from fake_alerts.supabase_client import insert_news_alert

INTERVAL_SECONDS = 300  # 5 minutes (change to 30 for demo)

def run_realtime_monitor():
    print("🌍 South India Disaster News Monitor Started")
    print(f"⏱ Checking every {INTERVAL_SECONDS} seconds\n")

    while True:
        try:
            news_items = fetch_live_disaster_news(limit=5)

            for item in news_items:
                print("Processing:", item["text"])

                result = detect_fake_alert(item["text"], item["source"])

                if result["status"] == "VERIFIED ALERT":
                    alert_data = {
                        "title": item["text"],
                        "message": "Verified disaster alert from live news",
                        "severity": "critical",
                        "alert_type": "news",
                        "source": item["source"],
                        "confidence": result["confidence"],
                        "region": "South India",
                        "verified": True
                    }

                    insert_news_alert(alert_data)
                    print("✅ STORED VERIFIED NEWS ALERT")

                else:
                    print("❌ Ignored:", result["status"])

                print("-" * 60)

        except Exception as e:
            print("⚠️ Error during monitoring:", e)

        print("🕒 Waiting for next cycle...\n")
        time.sleep(INTERVAL_SECONDS)


if __name__ == "__main__":
    run_realtime_monitor()
