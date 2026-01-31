
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

    if (!alerts || alerts.length === 0) {
        container.innerHTML = '<div class="no-data">NO ACTIVE SOS ALERTS</div>';
        return;
    }

    alerts.forEach(alert => {
        const card = document.createElement('div');
        card.className = `sos-card ${alert.status.toLowerCase()}`;
        if (alert.status === 'NEW') card.classList.add('new');

        // Try to get a better address if we only have coords
        let locationDisplay = alert.location_text || 'Unknown Location';
        if (locationDisplay.includes("Lat:") && !alert.address_resolved) {
            // Attempt Reverse Geocode
            resolveAddress(alert.latitude, alert.longitude, card);
        }

        // Card Content (No buttons here)
        card.innerHTML = `
            <div class="sos-header">
                <span class="sos-time">${new Date(alert.created_at).toLocaleTimeString()}</span>
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
            <span class="sos-modal-value">${new Date(alertItem.created_at).toLocaleString()}</span>
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
        msg.innerHTML = `<strong>NEW SOS:</strong> ${alertData.description.substring(0, 30)}...`;
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
        fetchSOSAlerts();
        subscribeToSOS();
    }
});
