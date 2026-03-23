import os
from twilio.rest import Client
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file in the project root
# Assuming the root is two levels up from this file (fake_alerts/twilio_utils.py)
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

class TwilioSMS:
    # TWILIO CREDENTIALS loaded from environment variables
    ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID')
    AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN')
    FROM_NUMBER = os.environ.get('TWILIO_PHONE_NUMBER')

    def __init__(self):
        missing = []
        if not self.ACCOUNT_SID: missing.append("TWILIO_ACCOUNT_SID")
        if not self.AUTH_TOKEN: missing.append("TWILIO_AUTH_TOKEN")
        if not self.FROM_NUMBER: missing.append("TWILIO_PHONE_NUMBER")
        
        if missing:
            print(f"Error: Missing environment variables: {', '.join(missing)}")
            print(f"Attempted to load from: {env_path}")
            self.client = None
            return
        self.client = Client(self.ACCOUNT_SID, self.AUTH_TOKEN)

    def send_message(self, to_number, body):
        """
        Sends an SMS message using Twilio.
        :param to_number: The recipient's phone number in E.164 format.
        :param body: The message content.
        :return: The message SID if successful, None otherwise.
        """
        if not self.client:
            print("Twilio client not initialized. Cannot send message.")
            return None
        try:
            message = self.client.messages.create(
                from_=self.FROM_NUMBER,
                to=to_number,
                body=body
            )
            print(f"SMS sent successfully! SID: {message.sid}")
            return message.sid
        except Exception as e:
            print(f"Failed to send SMS: {e}")
            return None

def send_alert_sms(to_number, alert_title, alert_message):
    """
    Sends a formatted alert SMS.
    """
    body = f"⚠️ SENTINEL ALERT: {alert_title}\n{alert_message}"
    sms = TwilioSMS()
    return sms.send_message(to_number, body)

if __name__ == "__main__":
    # Test call
    send_alert_sms("+919361488694", "System Test", "Test message from SENTINEL Python utility.")
