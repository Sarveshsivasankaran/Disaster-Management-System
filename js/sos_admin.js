
// Admin SOS Logic

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
        card.onclick = () => openSOSModal(alert);

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

// Init
document.addEventListener('DOMContentLoaded', () => {
    // Only run if we are on the admin page
    if (document.getElementById('sos-feed-container')) {
        // Delay slightly to allow main app.js to init map
        setTimeout(() => {
            fetchSOSAlerts();
            subscribeToSOS();
        }, 1500);
    }
});
