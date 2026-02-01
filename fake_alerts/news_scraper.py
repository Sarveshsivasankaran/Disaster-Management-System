import requests
from bs4 import BeautifulSoup

URL = "https://www.bbc.com/news"

def fetch_headlines():
    response = requests.get(URL)
    soup = BeautifulSoup(response.text, "html.parser")

    headlines = []

    for h3 in soup.find_all("h3"):
        text = h3.get_text(strip=True)
        if text:
            headlines.append(text)

    return headlines


if __name__ == "__main__":
    news = fetch_headlines()
    for i, headline in enumerate(news[:10], start=1):
        print(f"{i}. {headline}")
