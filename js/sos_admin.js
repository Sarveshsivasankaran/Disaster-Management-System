
// Admin SOS Logic

async function fetchSOSAlerts() {
    console.log("Fetching SOS Alerts...");
    const container = document.getElementById('sos-feed-container');
    if (!container) return;

    const { data, error } = await window.supabaseClient
        .from('sos_alerts')
        .select('*')
        .order('created_at', { ascending: false });

    if (error) {
        console.error("Error fetching SOS:", error);
        container.innerHTML = '<div class="error-msg">Failed to load alerts</div>';
        return;
    }

    renderSOSAlerts(data);
}

function renderSOSAlerts(alerts) {
    const container = document.getElementById('sos-feed-container');
    container.innerHTML = '';

    if (!alerts || alerts.length === 0) {
        container.innerHTML = '<div class="no-data">NO ACTIVE SOS ALERTS</div>';
        return;
    }

    alerts.forEach(async alert => {
        const card = document.createElement('div');
        card.className = `sos-card ${alert.status.toLowerCase()}`;

        // Try to get a better address if we only have coords
        let locationDisplay = alert.location_text || 'Unknown Location';
        if (locationDisplay.includes("Lat:") && !alert.address_resolved) {
            // Attempt Reverse Geocode
            resolveAddress(alert.latitude, alert.longitude, card);
        }

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
            ${getActionsHTML(alert)}
        `;
        container.appendChild(card);
    });
}

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

function getActionsHTML(alert) {
    if (alert.status !== 'NEW') return '';

    // Pass coords for deployment
    return `
        <div class="sos-actions">
            <button class="action-btn success-btn small-btn" onclick="updateSOSStatus('${alert.id}', 'ACCEPTED', ${alert.latitude}, ${alert.longitude}, '${alert.description.replace(/'/g, "\\'")}')">ACCEPT & DEPLOY</button>
            <button class="action-btn danger-btn small-btn" onclick="updateSOSStatus('${alert.id}', 'REJECTED')">REJECT & DELETE</button>
        </div>
    `;
}

async function updateSOSStatus(id, newStatus, lat = 0, lng = 0, desc = '') {

    if (newStatus === 'REJECTED') {
        if (!confirm("Are you sure you want to delete this alert?")) return;

        const { error } = await window.supabaseClient
            .from('sos_alerts')
            .delete()
            .eq('id', id);

        if (error) {
            console.error("Delete failed", error);
            alert("Failed to delete alert");
        } else {
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
        // Optimistic update or wait for realtime
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
