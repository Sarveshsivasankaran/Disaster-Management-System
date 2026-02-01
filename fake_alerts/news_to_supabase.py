from supabase_client import insert_news_alert

# Sample South India disaster news (REALISTIC)
title = "Heavy Rainfall Triggers Flooding in Chennai Suburbs"
message = (
    "Continuous heavy rainfall over the past 24 hours has caused severe flooding "
    "in several low-lying areas of Chennai, including Velachery and Tambaram. "
    "Authorities have issued warnings and rescue teams are on standby."
)

severity = "critical"

result = insert_news_alert(
    title=title,
    message=message,
    severity=severity,
    alert_type="news",
    source="News API",
    confidence=92,
    region="South India",
    verified=True
)

print("News inserted into Supabase successfully")
print(result)
