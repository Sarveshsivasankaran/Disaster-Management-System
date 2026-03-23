/**
 * Twilio SMS Service for SENTINEL Web Dashboard
 * Handles sending SMS and OTPs via Twilio REST API
 */

const TWILIO_SID = 'ACa7209437c9427fdbce3c43808c22eb43';
const TWILIO_TOKEN = '629d0346ecab6f0ed7bcf2dd06602b8a';
const TWILIO_FROM = '+16168670252';

class SmsService {
    /**
     * Sends a general SMS
     * @param {string} to - Destination phone number
     * @param {string} body - Message content
     */
    static async sendSms(to, body) {
        console.log(`SENTINEL SMS: Sending to ${to}...`);
        
        // Ensure phone number starts with +
        if (!to.startsWith('+')) {
            to = '+91' + to; // Default to India if no prefix
        }

        const url = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_SID}/Messages.json`;
        const auth = btoa(`${TWILIO_SID}:${TWILIO_TOKEN}`);

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Authorization': `Basic ${auth}`,
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: new URLSearchParams({
                    'To': to,
                    'From': TWILIO_FROM,
                    'Body': body
                })
            });

            const data = await response.json();
            if (response.ok) {
                console.log("SENTINEL SMS: Success!", data.sid);
                return { success: true, sid: data.sid };
            } else {
                console.error("SENTINEL SMS: API Error", data.message);
                return { success: false, error: data.message };
            }
        } catch (e) {
            console.error("SENTINEL SMS: Network Error", e);
            return { success: false, error: e.message };
        }
    }

    /**
     * Sends a verification OTP
     * @param {string} to - Destination phone number
     */
    static async sendOtp(to) {
        const otp = Math.floor(100000 + Math.random() * 900000);
        const body = `[SENTINEL] Your emergency verification code is: ${otp}. Do not share this code.`;
        
        const result = await this.sendSms(to, body);
        if (result.success) {
            return { success: true, otp: otp };
        }
        return result;
    }
}

// Expose to window for sos_admin.js
window.SmsService = SmsService;
