# live_news_feed.py
# Fetches REAL South India disaster-related news with summaries

import feedparser

# RSS feeds from trusted sources
RSS_FEEDS = [
    "https://www.thehindu.com/news/national/tamil-nadu/feeder/default.rss",
    "https://www.thehindu.com/news/national/kerala/feeder/default.rss",
    "https://www.thehindu.com/news/national/karnataka/feeder/default.rss",
    "https://timesofindia.indiatimes.com/rssfeeds/2950623.cms"  # South India
]

DISASTER_KEYWORDS = [
    "flood", "cyclone", "rain", "landslide", "earthquake",
    "storm", "heavy rainfall", "alert", "warning", "monsoon"
]


def fetch_live_disaster_news(limit=5):
    news_items = []

    for feed_url in RSS_FEEDS:
        feed = feedparser.parse(feed_url)

        for entry in feed.entries:
            title = entry.get("title", "")
            summary = entry.get("summary", "")

            text = f"{title}. {summary}"

            if any(k in text.lower() for k in DISASTER_KEYWORDS):
                news_items.append({
                    "text": text.strip(),
                    "source": feed.feed.get("title", "News Source")
                })

            if len(news_items) >= limit:
                return news_items

    return news_items
