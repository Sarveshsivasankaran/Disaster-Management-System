# Fake Alert Detection - Phase 2
# Text + Source based filtering

PANIC_KEYWORDS = [
    "massive", "huge", "worst", "destroyed",
    "thousands dead", "panic", "emergency",
    "breaking", "shocking", "alert!!!",
    "viral", "pls share", "urgent", "unconfirmed"
]

DISASTER_KEYWORDS = [
    "flood", "cyclone", "earthquake",
    "tsunami", "landslide", "dam burst"
]

OFFICIAL_SOURCES = [
    "the hindu", "times of india", "ndtv",
    "bbc", "government", "imd"
]

SOCIAL_SOURCES = [
    "instagram", "facebook", "whatsapp",
    "twitter", "telegram"
]


def detect_fake_alert(text, source):
    text = text.lower()
    source = source.lower()

    panic_found = [w for w in PANIC_KEYWORDS if w in text]
    disaster_found = [w for w in DISASTER_KEYWORDS if w in text]

    is_official = any(src in source for src in OFFICIAL_SOURCES)
    is_social = any(src in source for src in SOCIAL_SOURCES)

    # Decision logic
    if panic_found and disaster_found and is_social:
        status = "FAKE ALERT"
        reason = "Panic language from unverified social source"

    elif disaster_found and is_official:
        status = "VERIFIED ALERT"
        reason = "Reported by official news source"

    elif disaster_found:
        status = "NEEDS ADMIN REVIEW"
        reason = "Disaster mentioned but source is unclear"

    else:
        status = "SAFE / IRRELEVANT"
        reason = "No disaster-related content"

    return {
        "status": status,
        "reason": reason,
        "panic_keywords": panic_found,
        "disaster_keywords": disaster_found,
        "source": source
    }


# ---- Test ----
if __name__ == "__main__":
    text = input("Enter news or post text: ")
    source = input("Enter source (Instagram / The Hindu / etc): ")

    result = detect_fake_alert(text, source)

    print("\nAnalysis Result:")
    for key, value in result.items():
        print(f"{key}: {value}")
