import os
from twilio.rest import Client
<<<<<<< HEAD
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class TwilioSMS:
    # TWILIO CREDENTIALS loaded from environment variables
    ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID')
    AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN')
    FROM_NUMBER = os.environ.get('TWILIO_PHONE_NUMBER')

    def __init__(self):
        if not self.ACCOUNT_SID or not self.AUTH_TOKEN:
            print("Error: Twilio credentials not found in environment variables.")
            self.client = None
            return
=======

class TwilioSMS:
    # TWILIO CREDENTIALS
    ACCOUNT_SID = 'ACa7209437c9427fdbce3c43808c22eb43'
    # In a real scenario, this should be an environment variable
    AUTH_TOKEN = 'b0a8a2a1dce1b1b8da5b41b5fb0709f9' 
    FROM_NUMBER = '+16168670252'

    def __init__(self):
>>>>>>> parent of a73e8c8 (Revert "feat: Implement core application UI with home screen, dashboard, bottom navigation, and danger detection system.")
        self.client = Client(self.ACCOUNT_SID, self.AUTH_TOKEN)

    def send_message(self, to_number, body):
        """
        Sends an SMS message using Twilio.
        :param to_number: The recipient's phone number in E.164 format.
        :param body: The message content.
        :return: The message SID if successful, None otherwise.
        """
<<<<<<< HEAD
        if not self.client:
            print("Twilio client not initialized. Cannot send message.")
            return None
=======
>>>>>>> parent of a73e8c8 (Revert "feat: Implement core application UI with home screen, dashboard, bottom navigation, and danger detection system.")
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
