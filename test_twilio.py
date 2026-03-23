import os
from twilio.rest import Client
from dotenv import load_dotenv

load_dotenv(".env")

sid = os.getenv("TWILIO_ACCOUNT_SID")
token = os.getenv("TWILIO_AUTH_TOKEN")
from_no = os.getenv("TWILIO_PHONE_NUMBER")

print(f"Testing SID: {sid}")
print(f"Testing Token: {token}")
client = Client(sid, token)

try:
    message = client.messages.create(
        body="Sentinel Test",
        from_=from_no,
        to="+919361488694"
    )
    print(f"Success! SID: {message.sid}")
except Exception as e:
    print(f"Error: {e}")
