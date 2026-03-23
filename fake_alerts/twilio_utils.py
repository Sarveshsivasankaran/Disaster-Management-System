import os
from twilio.rest import Client

class TwilioSMS:
    # TWILIO CREDENTIALS
    ACCOUNT_SID = 'ACa7209437c9427fdbce3c43808c22eb43'
    # In a real scenario, this should be an environment variable
    AUTH_TOKEN = 'b0a8a2a1dce1b1b8da5b41b5fb0709f9' 
    FROM_NUMBER = '+16168670252'

    def __init__(self):
        self.client = Client(self.ACCOUNT_SID, self.AUTH_TOKEN)

    def send_message(self, to_number, body):
        """
        Sends an SMS message using Twilio.
        :param to_number: The recipient's phone number in E.164 format.
        :param body: The message content.
        :return: The message SID if successful, None otherwise.
        """
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
