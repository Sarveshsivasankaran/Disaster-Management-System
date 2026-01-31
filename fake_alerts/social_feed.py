# social_feed.py
# Simulated real-time social media feed for disaster alerts

import time
import random

SOCIAL_POSTS = [
    {
        "text": "Massive flood destroyed Chennai pls share urgently",
        "source": "Social Media"
    },
    {
        "text": "Cyclone warning issued by IMD for Tamil Nadu coast",
        "source": "IMD"
    },
    {
        "text": "Heavy rainfall expected in Chennai tomorrow",
        "source": "Local News"
    },
    {
        "text": "Unconfirmed reports of dam burst circulating online",
        "source": "Social Media"
    },
    {
        "text": "IMD releases orange alert for Chennai and nearby districts",
        "source": "IMD"
    },
    {
        "text": "Chennai weather is pleasant today",
        "source": "Unknown"
    }
]


def fetch_social_posts(batch_size=3):
    """
    Simulates fetching posts from social media platforms
    """
    return random.sample(SOCIAL_POSTS, batch_size)


if __name__ == "__main__":
    print("Fetching social media posts...\n")

    posts = fetch_social_posts()

    for post in posts:
        print(f"Source: {post['source']}")
        print(f"Post  : {post['text']}")
        print("-" * 40)
        time.sleep(1)
