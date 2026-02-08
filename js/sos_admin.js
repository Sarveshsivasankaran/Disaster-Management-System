// Admin SOS Logic

let sosMiniMap = null;
let sosMiniMarker = null;

function initSOSMiniMap(lat, lng) {
    const mapContainer = document.getElementById('sos-mini-map');
    if (!mapContainer) return;
    mapContainer.style.display = 'block';

    if (!sosMiniMap) {
        sosMiniMap = L.map('sos-mini-map', {
            zoomControl: false,
            attributionControl: false
        }).setView([lat, lng], 14);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            maxZoom: 19
        }).addTo(sosMiniMap);
    } else {
        sosMiniMap.setView([lat, lng], 14);
        sosMiniMap.invalidateSize();
    }

    if (sosMiniMarker) {
        sosMiniMap.removeLayer(sosMiniMarker);
    }

    const sosIcon = L.divIcon({
        className: 'sos-marker-mini',
        html: '<div class="sos-dot-mini"></div>',
        iconSize: [20, 20],
        iconAnchor: [10, 10]
    });

    sosMiniMarker = L.marker([lat, lng], { icon: sosIcon }).addTo(sosMiniMap);
}

// Add required CSS for the mini dot if not in styles.css
const style = document.createElement('style');
style.textContent = `
    .sos-marker-mini {
        display: flex;
        align-items: center;
        justify-content: center;
    }
    .sos-dot-mini {
        width: 12px;
        height: 12px;
        background: #ff2a2a;
        border-radius: 50%;
        box-shadow: 0 0 10px #ff2a2a, 0 0 20px #ff2a2a;
        animation: pulse-sos 1.5s infinite;
    }
    @keyframes pulse-sos {
        0% { transform: scale(1); opacity: 1; }
        50% { transform: scale(1.5); opacity: 0.5; }
        100% { transform: scale(1); opacity: 1; }
    }
`;
document.head.appendChild(style);

async function fetchSOSAlerts() {
    console.log("Fetching SOS Alerts...");
    const container = document.getElementById('sos-feed-container');
    if (!container) return;

    // Show loading state if needed, or just let it replace
    // container.innerHTML = '<div class="loading-spinner">Refreshing...</div>';

    const { data, error } = await window.supabaseClient
        .from('sos_alerts')
        .select('*')
        .neq('status', 'REJECTED') // Filter out rejected
        .order('created_at', { ascending: false });

    if (error) {
        console.error("Error fetching SOS:", error);
        container.innerHTML = '<div class="error-msg">Failed to load alerts</div>';
        return;
    }

    renderSOSAlerts(data);
}

// Make globally available for the Refresh button
window.fetchSOSAlerts = fetchSOSAlerts;

function renderSOSAlerts(alerts) {
    const container = document.getElementById('sos-feed-container');
    container.innerHTML = '';

    // Clear existing cues on map to sync with fresh list
    if (window.sentinel && window.sentinel.clearSOSMarkers) {
        window.sentinel.clearSOSMarkers();
    }

    if (!alerts || alerts.length === 0) {
        container.innerHTML = '<div class="no-data">NO ACTIVE SOS ALERTS</div>';
        return;
    }

    let acceptedCount = 0;

    alerts.forEach(alert => {
        if (alert.status === 'ACCEPTED') {
            acceptedCount++;
        }

        const card = document.createElement('div');
        card.className = `sos-card ${alert.status.toLowerCase()}`;
        if (alert.status === 'NEW') card.classList.add('new');

        // Restore Marker on Map if Accepted
        if (alert.status === 'ACCEPTED' && window.sentinel && window.sentinel.restoreSOSMarker) {
            // Escape description
            const safeDesc = (alert.description || '').replace(/'/g, "\\'");
            window.sentinel.restoreSOSMarker(alert.latitude, alert.longitude, safeDesc);
        }

        // Try to get a better address if we only have coords
        let locationDisplay = alert.location_text || 'Unknown Location';
        if (locationDisplay.includes("Lat:") && !alert.address_resolved) {
            // Attempt Reverse Geocode
            resolveAddress(alert.latitude, alert.longitude, card);
        }

        // Card Content (No buttons here)
        card.innerHTML = `
            <div class="sos-header">
                <span class="sos-time">${getDisplayTime(alert)}</span>
                <span class="sos-status badge ${getStatusBadgeClass(alert.status)}">${alert.status}</span>
            </div>
            <div class="sos-body">
                <h3>${alert.name} (${alert.phone})</h3>
                <p class="sos-loc">📍 <span class="loc-text">${locationDisplay}</span></p>
                <p class="sos-desc">"${alert.description}"</p>
            </div>
        `;

        // Make clickable
        card.onclick = () => {
            openSOSModal(alert);
            verifySOSAlert(alert);
        };

        container.appendChild(card);
    });

    // Update Victims Located Count (Accepted SOS)
    const victimsVal = document.getElementById('val-victims-located');
    if (victimsVal) {
        victimsVal.textContent = acceptedCount;
    }

    // Update Active Teams Count
    const teamsVal = document.getElementById('val-active-teams');
    if (teamsVal) {
        teamsVal.textContent = acceptedCount;
    }

    // Update Rescue Units Grid (Sync with Accepted SOS)
    const rescueGrid = document.getElementById('rescue-unit-grid');
    if (rescueGrid) {
        rescueGrid.innerHTML = ''; // Clear mock/old data

        if (acceptedCount === 0) {
            rescueGrid.innerHTML = '<div style="padding:20px; color:#aaa; text-align:center; width:100%;">NO ACTIVE RESCUE MISSIONS</div>';
        } else {
            alerts.forEach(alert => {
                if (alert.status === 'ACCEPTED') {
                    // Generate Unit ID from Alert ID segment or random
                    const unitId = alert.id.split('-')[0].toUpperCase();

                    const div = document.createElement('div');
                    div.className = 'unit-card';
                    div.innerHTML = `
                        <div class="unit-icon">🚁</div>
                        <div class="unit-info">
                            <h3>RAPID-RESP-${unitId}</h3>
                            <p>STATUS: <span style="color:#00ff9d; font-weight:bold;">DEPLOYED</span></p>
                            <p>DESTIN: ${alert.latitude.toFixed(4)}, ${alert.longitude.toFixed(4)}</p>
                            <p style="font-size:0.7em; margin-top:4px; opacity:0.7;">MSN: ${alert.id.substring(0, 8)}...</p>
                        </div>
                    `;
                    rescueGrid.appendChild(div);
                }
            });
        }
    }
}

// --- MODAL LOGIC ---

function openSOSModal(alertItem) {
    const modal = document.getElementById('sos-details-modal');
    const body = document.getElementById('sos-modal-body');
    const actions = document.getElementById('sos-modal-actions');

    if (!modal || !body || !actions) return;

    // Populate Details
    body.innerHTML = `
        <div class="sos-modal-detail-row">
            <span class="sos-modal-label">REPORTED TIME</span>
            <span class="sos-modal-value">${getDisplayTime(alertItem)}</span>
        </div>
        <div class="sos-modal-detail-row">
            <span class="sos-modal-label">CONTACT INFO</span>
            <span class="sos-modal-value highlight">${alertItem.name}</span><br>
            <span class="sos-modal-value">${alertItem.phone}</span>
        </div>
        <div class="sos-modal-detail-row">
            <span class="sos-modal-label">LOCATION</span>
            <span class="sos-modal-value">${alertItem.location_text || `${alertItem.latitude}, ${alertItem.longitude}`}</span>
            <div style="margin-top:5px; font-size: 0.8em; color:#888;">Lat: ${alertItem.latitude}, Lng: ${alertItem.longitude}</div>
        </div>
        <div class="sos-modal-detail-row">
            <span class="sos-modal-label">EMERGENCY DESCRIPTION</span>
            <p style="margin-top:5px; line-height:1.5;">"${alertItem.description}"</p>
        </div>
        <div class="sos-modal-detail-row">
            <span class="sos-modal-label">CURRENT STATUS</span>
            <span class="status-badge ${getStatusBadgeClass(alertItem.status)}">${alertItem.status}</span>
        </div>
    `;

    // Populate Actions
    if (alertItem.status === 'NEW') {
        // Escaping description for function call
        const safeDesc = alertItem.description.replace(/'/g, "\\'");

        actions.innerHTML = `
            <button class="full-btn btn-accept" onclick="updateSOSStatus('${alertItem.id}', 'ACCEPTED', ${alertItem.latitude}, ${alertItem.longitude}, '${safeDesc}')">
                ✅ ACCEPT & DEPLOY RESCUE
            </button>
            <button class="full-btn btn-reject" onclick="updateSOSStatus('${alertItem.id}', 'REJECTED')">
                ❌ REJECT MARKER
            </button>
        `;
    } else {
        actions.innerHTML = `
            <button class="full-btn" style="border:1px solid #555; color:#aaa;" onclick="closeSOSModal()">CLOSE DETAILS</button>
        `;
    }

    // Show
    modal.classList.add('open');
}

function closeSOSModal() {
    const modal = document.getElementById('sos-details-modal');
    if (modal) modal.classList.remove('open');
}

// Make globally available for button onclicks
window.closeSOSModal = closeSOSModal;
window.updateSOSStatus = updateSOSStatus;


async function resolveAddress(lat, lng, cardElement) {
    try {
        const url = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lng}&localityLanguage=en`;
        const resp = await fetch(url);
        const data = await resp.json();
        const city = data.city || data.locality || '';
        const country = data.countryName || '';
        const address = `${city}, ${country}` || `${lat}, ${lng}`;

        const locSpan = cardElement.querySelector('.loc-text');
        if (locSpan) locSpan.textContent = address;

    } catch (e) {
        console.warn("Reverse geocode failed", e);
    }
}

function getStatusBadgeClass(status) {
    if (status === 'NEW') return 'critical';
    if (status === 'ACCEPTED') return 'warning'; // In progress
    if (status === 'REJECTED') return 'normal'; // Resolved/Rejected
    return '';
}

async function updateSOSStatus(id, newStatus, lat = 0, lng = 0, desc = '') {

    if (newStatus === 'REJECTED') {
        if (!confirm("Are you sure you want to reject/delete this alert?")) return;

        const { error } = await window.supabaseClient
            .from('sos_alerts')
            .delete()
            .eq('id', id);

        if (error) {
            console.error("Delete failed", error);
            alert("Failed to delete alert");
        } else {
            closeSOSModal();
            fetchSOSAlerts(); // Refresh list to remove item
        }
        return;
    }

    const { error } = await window.supabaseClient
        .from('sos_alerts')
        .update({ status: newStatus })
        .eq('id', id);

    if (error) {
        console.error("Update failed", error);
        alert("Failed to update status");
    } else {
        closeSOSModal();
        fetchSOSAlerts();

        if (newStatus === 'ACCEPTED') {
            alert("Rescue Operations Assigned & Deployed!");

            // Trigger Sentinel Dashboard Deployment
            if (window.sentinel && lat !== 0 && lng !== 0) {
                window.sentinel.deployRescueToLocation(lat, lng, desc);
            }
        }
    }
}

// Helper to get best available time
function getDisplayTime(alert) {
    if (alert.date && alert.time) {
        return `${alert.date} ${alert.time}`;
    }
    return formatSOSTime(alert.created_at);
}

// Helper for safe time formatting (Fallback)
function formatSOSTime(timestamp) {
    if (!timestamp) return 'Time Unavailable';
    const date = new Date(timestamp);
    if (isNaN(date.getTime()) || date.getFullYear() === 1970) {
        return 'Time Unavailable';
    }
    return date.toLocaleString('en-IN');
}

// Realtime Subscription
function subscribeToSOS() {
    window.supabaseClient
        .channel('public:sos_alerts')
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'sos_alerts' }, payload => {
            console.log('New SOS!', payload);
            showNotification(payload.new);
            fetchSOSAlerts();
        })
        .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'sos_alerts' }, payload => {
            fetchSOSAlerts();
        })
        .subscribe();
}

function showNotification(alertData) {
    const popup = document.getElementById('sos-popup');
    const msg = document.getElementById('popup-msg');

    if (popup && msg) {
        msg.innerHTML = `<strong>NEW SOS (${getDisplayTime(alertData)}):</strong> ${alertData.description ? alertData.description.substring(0, 30) : 'Emergency'}...`;
        popup.classList.add('visible');

        // Play sound if possible?
        // const audio = new Audio('alert.mp3'); audio.play();

        setTimeout(() => {
            popup.classList.remove('visible');
        }, 5000);
    }
}

// --- SOS VERIFICATION LOGIC (NEWS & NASA GUARDIAN) ---

async function verifySOSAlert(alert) {
    const placeholder = document.getElementById('verify-placeholder');
    const content = document.getElementById('verify-content');
    if (!placeholder || !content) return;

    // Show Loading
    placeholder.style.display = 'none';
    content.style.display = 'block';
    content.innerHTML = `
        <div class="verify-section">
            <h3 style="color:var(--neon-blue);"><span class="icon">📡</span> SECURE INTEL VERIFICATION...</h3>
            <div class="loading-spinner">Synchronizing Ground Sensors & Satellite Data...</div>
        </div>
    `;

    try {
        const lat = alert.latitude;
        const lng = alert.longitude;

        // 0. Update Mini-Map
        initSOSMiniMap(lat, lng);

        // 1. Resolve Location Name
        const geoUrl = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lng}&localityLanguage=en`;
        const geoData = await (await fetch(geoUrl)).json();
        const locationName = geoData.city || geoData.locality || "Disaster Zone";

        // 2. FETCH TRIPLE-GATE DATA
        // A. Weather & Environmental Stress (Open-Meteo)
        const weather = await fetchWeatherSignal(lat, lng);

        // B. Ground Sensor Network (Supabase Buoys/Poles)
        const nearbySensors = await fetchNearbySensorData(lat, lng);

        // C. External Intelligence (NASA & News)
        const [news, nasaEvents] = await Promise.all([
            fetchLocalNews(locationName),
            fetchNASAData(lat, lng)
        ]);

        // D. Cluster Analysis (Are others reporting nearby?)
        const clusterCount = await checkAlertClustering(alert);

        // E. User Identity verification
        const userProfile = await checkUserRegistration(alert.phone);

        // F. Risk Zone Analysis
        const nearbyHazard = checkHazardProximity(lat, lng);

        // 3. SECURE SCORING
        const score = calculateUltimateScore(alert, weather, nearbySensors, news, nasaEvents, clusterCount, userProfile, nearbyHazard);

        // 4. PREPARE REASONING
        const reasoning = generateDeepReasoning(score, weather, nearbySensors, news, nasaEvents, clusterCount, userProfile, nearbyHazard);

        // 5. RENDER
        renderDeepVerificationPanel(alert, locationName, weather, nearbySensors, news, nasaEvents, score, reasoning, clusterCount, userProfile, nearbyHazard);

    } catch (e) {
        console.error("Deep Verification Failed", e);
        content.innerHTML = `<div class="error-msg">Intelligence Hub Connection Error</div>`;
    }
}

async function fetchWeatherSignal(lat, lng) {
    try {
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}&current=temperature_2m,relative_humidity_2m,rain,surface_pressure,wind_speed_10m&forecast_days=1`;
        const resp = await fetch(url);
        return await resp.json();
    } catch (e) { return null; }
}

async function fetchNearbySensorData(lat, lng) {
    try {
        // Fetch sensors within 0.1 degree (~11km)
        const { data } = await window.supabaseClient
            .from('buoys')
            .select('*')
            .gte('latitude', lat - 0.1)
            .lte('latitude', lat + 0.1)
            .gte('longitude', lng - 0.1)
            .lte('longitude', lng + 0.1)
            .order('created_at', { ascending: false })
            .limit(10);
        return data || [];
    } catch (e) { return []; }
}

async function checkAlertClustering(activeAlert) {
    try {
        const { count } = await window.supabaseClient
            .from('sos_alerts')
            .select('*', { count: 'exact', head: true })
            .neq('id', activeAlert.id)
            .eq('status', 'NEW')
            .gte('latitude', activeAlert.latitude - 0.05)
            .lte('latitude', activeAlert.latitude + 0.05)
            .gte('longitude', activeAlert.longitude - 0.05)
            .lte('longitude', activeAlert.longitude + 0.05);
        return count || 0;
    } catch (e) { return 0; }
}

async function checkUserRegistration(phone) {
    try {
        const { data } = await window.supabaseClient
            .from('mobile_users')
            .select('*')
            .eq('phone', phone)
            .single();
        return data;
    } catch (e) { return null; }
}

function checkHazardProximity(lat, lng) {
    // Defined Hazards (matching app.js demo locations relative to base)
    // Assuming base is ~ Chennai 13.0827, 80.2707 for this context
    const hazards = [
        { lat: 13.0877, lng: 80.2827, radius: 1500, name: "DAM DISCHARGE ZONE" },
        { lat: 13.0747, lng: 80.2657, radius: 1200, name: "LOW LYING FLOOD AREA" },
        { lat: 13.0827, lng: 80.2707, radius: 5000, name: "GENERAL FLOOD ZONE" } // Catch-all for demo
    ];

    return hazards.find(h => {
        const dist = Math.sqrt(Math.pow(lat - h.lat, 2) + Math.pow(lng - h.lng, 2)) * 111000; // Rough meters
        return dist < h.radius;
    });
}

function calculateUltimateScore(alert, weather, sensors, news, nasa, clusters, user, hazard) {
    let score = 20; // Base trust

    // 1. Identity & Reputation (+30 max)
    if (user) {
        score += 20; // Registered User
        // Bonus for account age could go here
    }
    // Phone format check (Simple proxy)
    if (alert.phone && alert.phone.length >= 10) score += 5;

    // 2. Weather Proofing (+20 max)
    if (weather && weather.current) {
        if (weather.current.rain > 0.5) score += 10;
        if (weather.current.wind_speed_10m > 30) score += 10;
    }

    // 3. Hard Sensor/Hazard Verification (+30 max)
    const anomaly = sensors.find(s => s.water_level > 4.5 || s.wave_height > 2.5);
    if (anomaly) score += 20;
    else if (sensors.length > 0) score += 5; // Sensors are active

    if (hazard) score += 15; // In a known danger zone

    // 4. Social & Global Proofing (+10 max)
    if (news.length > 0) score += 5;
    if (nasa.length > 0) score += 5;

    // 5. Community/Cluster Validation (+10)
    if (clusters > 1) score += 10;
    else if (clusters === 1) score += 5;

    // 6. Keyword Validation (+5)
    const text = alert.description.toLowerCase();
    if (text.includes('help') || text.includes('emergency') || text.includes('flood') || text.includes('fire') || text.includes('stuck') || text.includes('trapped')) score += 5;

    return Math.min(score, 100);
}

function generateDeepReasoning(score, weather, sensors, news, nasa, clusters, user, hazard) {
    const lines = [];
    if (user) lines.push(`<span class="reason-valid">✅ IDENTITY:</span> Caller is a registered verified user.`);
    else lines.push(`<span class="reason-warn">⚠️ IDENTITY:</span> Unregistered / Guest user.`);

    if (hazard) lines.push(`<span class="reason-critical">🚨 ZONE:</span> Location is inside ${hazard.name}.`);

    if (weather && weather.current.rain > 0.5) lines.push("🌧️ ENVIRONMENT: Active precipitation confirmed.");
    if (sensors.some(s => s.water_level > 4.5)) lines.push("🌊 SENSORS: Critical water levels detected nearby.");

    if (clusters > 0) lines.push(`🤝 CLUSTER: ${clusters} other alerts in this sector.`);
    if (news.length > 0) lines.push("📰 NEWS: Public reports match disaster profile.");

    if (lines.length === 0) return "No secondary environmental or sensor data currently matches this report.";
    return lines.join("<br>");
}

function renderDeepVerificationPanel(alert, location, weather, sensors, news, nasa, score, reasoning, clusters, user, hazard) {
    const content = document.getElementById('verify-content');
    const intelClass = score > 70 ? 'intel-high' : (score > 40 ? 'intel-med' : 'intel-low');
    const intelText = score > 70 ? 'HIGH TRUST' : (score > 40 ? 'MODERATE TRUST' : 'LOW TRUST');
    const color = score > 70 ? '#00ff9d' : (score > 40 ? '#ffaa00' : '#ff2a2a');

    content.innerHTML = `
        <div class="intel-summary">
            <div class="intel-badge" style="background:${color}; color:#000; box-shadow: 0 0 15px ${color};">${intelText}</div>
            <div style="font-size:14px; margin-top:5px;">AI Confidence: <strong style="color:${color}; font-size:1.2em;">${score}%</strong></div>
        </div>

        <div class="verify-section" style="border-left:3px solid ${color};">
            <h3 style="color:var(--neon-green);"><span class="icon">🛡️</span> VERIFICATION LOG</h3>
            <div style="font-size:12px; line-height:1.6; color:#e0e6ed;">
                ${reasoning}
            </div>
        </div>

        <div class="verify-grid">
             <div class="verify-section">
                <h3><span class="icon">👤</span> IDENTITY</h3>
                <div class="nasa-data-row"><span>STATUS</span><span class="nasa-val ${user ? 'highlight-green' : 'highlight-amber'}">${user ? 'VERIFIED' : 'GUEST'}</span></div>
                ${user ? `<div class="nasa-data-row"><span>JOINED</span><span class="nasa-val text-xs">${new Date(user.created_at).toLocaleDateString()}</span></div>` : ''}
                <div class="nasa-data-row"><span>PHONE</span><span class="nasa-val">${alert.phone}</span></div>
                <button class="action-btn small outline" onclick="initiateCall('${alert.phone}', '${alert.name}')">📞 CALL</button>
            </div>

            <div class="verify-section">
                <h3><span class="icon">🌡️</span> METRICS</h3>
                <div class="nasa-data-row"><span>TEMP</span><span class="nasa-val">${weather?.current?.temperature_2m || '--'}°C</span></div>
                <div class="nasa-data-row"><span>WIND</span><span class="nasa-val">${weather?.current?.wind_speed_10m || '--'} km/h</span></div>
                <div class="nasa-data-row"><span>RISK</span><span class="nasa-val">${hazard ? 'CRITICAL' : 'NORMAL'}</span></div>
            </div>
        </div>
       
        <div class="verify-section">
            <h3><span class="icon">🏁</span> COMMAND RECOMMENDATION</h3>
            <p style="font-size:13px; font-weight:bold; color:${color};">
                ${score > 70
            ? "✅ HIGH PRIORITY: IMMEDIATE DEPLOYMENT RECOMMENDED."
            : (score > 40 ? "⚠️ CHECK REQUIRED: ATTEMPT CONTACT BEFORE DEPLOYING." : "⛔ LOW PRIORITY: FLAGGED AS POTENTIAL SPAM.")}
            </p>
        </div>
    `;
}


async function fetchLocalNews(location) {
    try {
        const query = encodeURIComponent(`${location} emergency flood disaster`);
        const rssUrl = `https://news.google.com/rss/search?q=${query}&hl=en-IN&gl=IN&ceid=IN:en`;
        const apiResp = await fetch(`https://api.rss2json.com/v1/api.json?rss_url=${encodeURIComponent(rssUrl)}`);
        const data = await apiResp.json();
        return data.items ? data.items.slice(0, 3) : [];
    } catch (e) {
        return [];
    }
}

// --- SOS VERIFICATION LOGIC (NEWS & NASA GUARDIAN) ---
// ... (previous logic up to line 577)


// --- TWILIO VOICE INTEGRATION ---
let twilioDevice = null;
let currentConnection = null;

async function setupTwilioDevice() {
    try {
        console.log("Initializing Voice Uplink...");

        // MOCK TOKEN: In production, fetch this from your backend
        // const response = await fetch('/api/voice-token');
        // const data = await response.json();
        const token = "MOCK_TWILIO_TOKEN_FOR_DEMO";

        if (typeof Twilio !== 'undefined') {
            twilioDevice = new Twilio.Device(token, {
                codecPreferences: ['opus', 'pcmu'],
                fakeLocalDTMF: true,
                enableRingingState: true
            });

            twilioDevice.on('ready', (device) => {
                console.log('Secure Line Ready');
            });

            twilioDevice.on('error', (error) => {
                console.warn('Voice Protocol Error:', error.message);
            });
        }
    } catch (e) {
        console.error("Voice setup failed:", e);
    }
}

// Initialize on load
setupTwilioDevice();

// --- CALL INTERFACE LOGIC ---
let callTimerInterval = null;
let callDurationSeconds = 0;

function initiateCall(phone, name) {
    const overlay = document.getElementById('call-interface-overlay');
    const nameEl = document.getElementById('call-name');
    const numberEl = document.getElementById('call-number');
    const statusEl = document.getElementById('call-status');
    const timerEl = document.getElementById('call-timer');
    const avatarText = document.querySelector('.call-avatar-text');

    if (!overlay) return;

    // Reset State
    stopCallTimer();
    callDurationSeconds = 0;
    if (timerEl) {
        timerEl.textContent = "00:00";
        timerEl.classList.remove('visible');
    }

    // Set Details
    if (nameEl) nameEl.textContent = name || "Unknown Caller";
    if (numberEl) numberEl.textContent = phone || "Unknown Number";
    if (statusEl) {
        statusEl.textContent = "ESTABLISHING UPLINK...";
        statusEl.style.color = "var(--neon-amber)";
    }
    if (avatarText) avatarText.textContent = name ? name.substring(0, 2).toUpperCase() : "?";

    // Show Overlay
    overlay.classList.add('active');

    // Attempt Verification Call
    if (twilioDevice) {
        const params = { To: phone };
        // This will connect if the token is valid. 
        // Since we are mocking, we simulate the state changes visually.
        // currentConnection = twilioDevice.connect(params);

        // SIMULATION FOR DEMO (Since we lack a backend token server)
        setTimeout(() => {
            if (statusEl) statusEl.textContent = "SECURE HANDSHAKE...";
        }, 1000);

        setTimeout(() => {
            if (statusEl) {
                statusEl.textContent = "VOICE CHANNEL OPEN";
                statusEl.style.color = "var(--neon-green)";
            }
            startCallTimer();
        }, 2500);

    } else {
        // Fallback if SDK fails
        statusEl.textContent = "SDK OFFLINE - DIALING NATIVE...";
        setTimeout(() => window.location.href = `tel:${phone}`, 1500);
    }
}

function startCallTimer() {
    const timerEl = document.getElementById('call-timer');
    if (timerEl) timerEl.classList.add('visible');

    callTimerInterval = setInterval(() => {
        callDurationSeconds++;
        const mins = Math.floor(callDurationSeconds / 60).toString().padStart(2, '0');
        const secs = (callDurationSeconds % 60).toString().padStart(2, '0');
        if (timerEl) timerEl.textContent = `${mins}:${secs}`;
    }, 1000);
}

function stopCallTimer() {
    if (callTimerInterval) clearInterval(callTimerInterval);
}

function endCall() {
    if (currentConnection) {
        currentConnection.disconnect();
        currentConnection = null;
    }

    stopCallTimer();
    const overlay = document.getElementById('call-interface-overlay');
    const statusEl = document.getElementById('call-status');

    if (statusEl) {
        statusEl.textContent = "LINK TERMINATED";
        statusEl.style.color = "var(--neon-red)";
    }

    setTimeout(() => {
        if (overlay) overlay.classList.remove('active');
    }, 1000);
}

function toggleMute(btn) {
    btn.classList.toggle('active');
    // Logic to actually mute audio stream would go here
}

function toggleSpeaker(btn) {
    btn.classList.toggle('active');
}

// Make globally available
window.initiateCall = initiateCall;
window.endCall = endCall;
window.toggleMute = toggleMute;
window.toggleSpeaker = toggleSpeaker;

async function fetchNASAData(lat, lng) {
    try {
        // NASA EONET API
        const resp = await fetch('https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=20');
        const data = await resp.json();

        // Filter events near location (within 2 degrees for simulation/demo range)
        return data.events.filter(ev => {
            if (!ev.geometry || ev.geometry.length === 0) return false;
            const geom = ev.geometry[0];
            const evLat = geom.coordinates[1];
            const evLng = geom.coordinates[0];
            const dist = Math.sqrt(Math.pow(lat - evLat, 2) + Math.pow(lng - evLng, 2));
            return dist < 2.0;
        });
    } catch (e) {
        return [];
    }
}

// Make globally available
window.verifySOSAlert = verifySOSAlert;

// Update DOMContentLoaded to ensure verification panel is ready
document.addEventListener('DOMContentLoaded', () => {
    // Only run if we are on the admin page
    if (document.getElementById('sos-feed-container')) {
        setTimeout(() => {
            fetchSOSAlerts();
            subscribeToSOS();
        }, 1500);
    }
});
