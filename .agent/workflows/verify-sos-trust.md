---
description: Verify SOS Authentication and Trust System
---

1. Open the dashboard (index.html),
2. Navigate to the **SOS ALERTS** tab,
3. If no alerts are present, wait for a simulated alert or trigger one manually (if testing tools allow) or checking the database,
4. Click on an alert card to open the **SOS DETAIL & VERIFICATION** panel,
5. In the Verification Panel, verify the following:
   - **Identity Status**: Should show "VERIFIED" (green) if the phone number exists in `mobile_users` table, or "GUEST" (amber) otherwise,
   - **Risk Zone**: Should show "CRITICAL" if the location is near a known hazard (e.g., Dam Discharge Zone), otherwise "NORMAL",
   - **Metrics**: Check if Temperature and Wind data are displayed (fetched from Open-Meteo),
   - **Trust Score**: The AI Confidence score (0-100%) and Trust Level (LOW/MODERATE/HIGH) should reflect the combination of these factors,
   - **Verification Log**: Should list specific reasons for the score (e.g., "✅ IDENTITY: Caller is a registered verified user", "🚨 ZONE: Location is inside DAM DISCHARGE ZONE"),
6. Click the **"📞 CALL"** button to simulate a verification call,
7. Verify that the **Command Recommendation** aligns with the score (e.g., "HIGH PRIORITY" for high scores),
