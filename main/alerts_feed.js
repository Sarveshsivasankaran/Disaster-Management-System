// alerts_feed.js
// Displays VERIFIED South India disaster news in real time

import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm";

// 🔐 Supabase frontend credentials (ANON key only)
const SUPABASE_URL = "https://nqipgzknhlfsrezssoyr.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xaXBnemtuaGxmc3JlenNzb3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNzQ4ODYsImV4cCI6MjA3Mzk1MDg4Nn0.M1xc6HtScdDjemguonpPgmo8EF0A93OoHvy4LACO24E";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const alertContainer = document.getElementById("alert-feed");

// Format time to IST
function formatTime(timestamp) {
  return new Date(timestamp).toLocaleTimeString("en-IN", {
    timeZone: "Asia/Kolkata",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

// Render one alert card
function renderAlert(alert) {
  const card = document.createElement("div");
  card.className = `alert-item ${alert.severity || "info"}`;

  card.innerHTML = `
    <div class="alert-time">${formatTime(alert.created_at)}</div>

    <div class="alert-msg">
      <strong>${alert.title}</strong>

      <p style="margin:6px 0;font-size:13px;line-height:1.4">
        ${alert.message}
      </p>

      <div style="display:flex;gap:10px;font-size:11px;opacity:0.85">
        <span style="color:#4CAF50;font-weight:bold">✔ VERIFIED</span>
        <span>Source: ${alert.source || "Trusted News"}</span>
        <span>Confidence: ${alert.confidence || "--"}%</span>
      </div>

      <div style="height:4px;background:#333;margin-top:4px">
        <div style="
          height:4px;
          width:${alert.confidence || 50}%;
          background:${alert.confidence > 80 ? "#4CAF50" : "#FFC107"};
        "></div>
      </div>
    </div>
  `;

  alertContainer.prepend(card);
}

// Load existing alerts
async function loadInitialAlerts() {
  alertContainer.innerHTML = "";

  const { data, error } = await supabase
    .from("alerts")
    .select("*")
    .eq("alert_type", "news")
    .eq("verified", true)
    .eq("region", "South India")
    .order("created_at", { ascending: false })
    .limit(5);

  if (error) {
    console.error("Failed to load alerts:", error);
    return;
  }

  data.forEach(renderAlert);
}

// Subscribe to realtime inserts
function subscribeToAlerts() {
  supabase
    .channel("south-india-verified-news")
    .on(
      "postgres_changes",
      {
        event: "INSERT",
        schema: "public",
        table: "alerts",
      },
      (payload) => {
        const alert = payload.new;

        if (
          alert.alert_type === "news" &&
          alert.verified === true &&
          alert.region === "South India"
        ) {
          renderAlert(alert);
        }
      }
    )
    .subscribe();
}

// INIT
loadInitialAlerts();
subscribeToAlerts();
