import requests

# ==================================================
# CONFIG
# ==================================================
FACT_CHECK_API_KEY = "AIzaSyANoJTsKrY7VlRKYIVTlh5sGlm4JKofuGo"
FACT_CHECK_URL = "https://factchecktools.googleapis.com/v1alpha1/claims:search"

PANIC_KEYWORDS = [
    "massive", "huge", "worst", "destroyed",
    "thousands dead", "panic", "breaking",
    "shocking", "urgent", "pls share", "viral"
]

DISASTER_KEYWORDS = [
    "flood", "cyclone", "earthquake",
    "tsunami", "landslide", "dam burst"
]

SOURCE_CREDIBILITY = {
    "government": 0.95,
    "imd": 0.95,
    "ndrf": 0.95,
    "the hindu": 0.85,
    "times of india": 0.80,
    "ndtv": 0.80,
    "bbc": 0.85,
    "official": 0.90,
    "unknown": 0.30,
    "social": 0.20
}

# ==================================================
# SOURCE TRUST
# ==================================================
def get_source_credibility(source_name):
    source_name = source_name.lower()
    for key in SOURCE_CREDIBILITY:
        if key in source_name:
            return SOURCE_CREDIBILITY[key]
    return SOURCE_CREDIBILITY["unknown"]

# ==================================================
# KEYWORD ANALYSIS
# ==================================================
def keyword_analysis(text):
    text = text.lower()
    return {
        "panic_found": [w for w in PANIC_KEYWORDS if w in text],
        "disaster_found": [w for w in DISASTER_KEYWORDS if w in text]
    }

# ==================================================
# FACT CHECK API (SAFE)
# ==================================================
def check_fact_claim(claim_text):
    try:
        params = {
            "query": claim_text,
            "languageCode": "en",
            "key": FACT_CHECK_API_KEY
        }

        response = requests.get(FACT_CHECK_URL, params=params, timeout=8)

        if response.status_code != 200:
            return {"found": False, "message": "Fact-check service unavailable"}

        data = response.json()

        if "claims" not in data or not data["claims"]:
            return {"found": False, "message": "No fact-check available"}

        claim = data["claims"][0]
        review = claim.get("claimReview", [{}])[0]

        return {
            "found": True,
            "rating": review.get("textualRating", "Unknown"),
            "publisher": review.get("publisher", {}).get("name", "Unknown"),
            "review_url": review.get("url", "N/A")
        }

    except Exception:
        return {"found": False, "message": "Fact-check service error"}

# ==================================================
# CONFIDENCE SCORE
# ==================================================
def calculate_confidence(fact_result, keywords, source_name):
    confidence = 0

    # Fact-check weight
    if fact_result.get("found"):
        rating = fact_result.get("rating", "").lower()
        if "true" in rating or "correct" in rating:
            confidence += 60
        elif "false" in rating or "misleading" in rating:
            confidence += 60

    # Source credibility (0–20)
    confidence += int(get_source_credibility(source_name) * 20)

    # Linguistic signals
    if not keywords["panic_found"]:
        confidence += 10
    if keywords["disaster_found"]:
        confidence += 10

    return min(confidence, 100)

# ==================================================
# HYBRID DECISION ENGINE
# ==================================================
def detect_fake_alert(claim_text, source_name="unknown"):
    keywords = keyword_analysis(claim_text)
    fact_result = check_fact_claim(claim_text)
    confidence = calculate_confidence(fact_result, keywords, source_name)

    # Highest authority: Fact-check
    if fact_result.get("found"):
        rating = fact_result["rating"].lower()

        if "false" in rating or "misleading" in rating:
            return {
                "status": "FAKE ALERT",
                "confidence": f"{confidence}%",
                "reason": "Marked false by verified fact-check source",
                "keywords": keywords,
                "fact_check": fact_result
            }

        if "true" in rating or "correct" in rating:
            return {
                "status": "VERIFIED ALERT",
                "confidence": f"{confidence}%",
                "reason": "Verified by trusted fact-check organization",
                "keywords": keywords,
                "fact_check": fact_result
            }

    # Fallback: Keyword logic
    if keywords["panic_found"] and keywords["disaster_found"]:
        return {
            "status": "FAKE ALERT",
            "confidence": f"{confidence}%",
            "reason": "Panic-inducing language without verification",
            "keywords": keywords,
            "fact_check": fact_result
        }

    if keywords["disaster_found"]:
        return {
            "status": "NEEDS ADMIN REVIEW",
            "confidence": f"{confidence}%",
            "reason": "Disaster mentioned but not verified",
            "keywords": keywords,
            "fact_check": fact_result
        }

    return {
        "status": "SAFE / IRRELEVANT",
        "confidence": f"{confidence}%",
        "reason": "No disaster-related content detected",
        "keywords": keywords,
        "fact_check": {}
    }

# ==================================================
# DEMO RUN
# ==================================================
if __name__ == "__main__":
    claim = input("Enter disaster-related claim: ")
    source = input("Enter source (IMD / The Hindu / Social Media): ")

    result = detect_fake_alert(claim, source)

    print("\n========= FINAL DECISION =========")
    print("Status     :", result["status"])
    print("Confidence :", result["confidence"])
    print("Reason     :", result["reason"])
    print("Keywords   :", result["keywords"])
    print("Fact Check :", result["fact_check"])
