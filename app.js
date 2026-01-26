import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.38.0/+esm';

// ============================================================================
// FUTURISTIC DASHBOARD CONTROLLER
// ============================================================================

class SentinelDashboard {
    constructor() {
        this.supabaseUrl = localStorage.getItem('supabaseUrl') || '';
        this.supabaseKey = localStorage.getItem('supabaseKey') || '';
        this.map = null;
        this.riskChart = null;
        this.timers = [];

        this.init();
    }

    init() {
        console.log("SENTINEL: Initializing Systems...");

        // 1. Core UI Setup
        this.setupNavigation();
        this.startRealTimeClock();

        // 2. Visualization Initialization
        try {
            this.initMap();
            this.initRiskMeter();
        } catch (e) {
            console.warn("Visualization init warning:", e);
        }

        // 3. Simulations (Make it alive)
        this.startSensorSimulation();
        this.startRandomAlerts();

        console.log("SENTINEL: Systems Online.");
    }

    // ========================================================================
    // 1. CORE UI
    // ========================================================================

    setupNavigation() {
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', (e) => {
                e.preventDefault();

                // Active State
                document.querySelectorAll('.nav-item').forEach(nav => nav.classList.remove('active'));
                item.classList.add('active');

                // View Switching
                const sectionId = item.dataset.section;
                document.querySelectorAll('.content-view').forEach(view => view.classList.remove('active'));
                const targetView = document.getElementById(sectionId);
                if (targetView) targetView.classList.add('active');

                // Resize map if visible (fix leaflet rendering issue on tab switch)
                if (sectionId === 'dashboard' && this.map) {
                    setTimeout(() => this.map.invalidateSize(), 200);
                }
            });
        });

        // Top Bar Buttons
        const refreshBtn = document.getElementById('refresh-btn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.simulateRefresh();
            });
        }
    }

    startRealTimeClock() {
        const timeDisplay = document.getElementById('server-time');
        if (!timeDisplay) return;

        setInterval(() => {
            const now = new Date();
            timeDisplay.textContent = now.toISOString().split('T')[1].split('.')[0] + " UTC";
        }, 1000);
    }

    simulateRefresh() {
        const btn = document.getElementById('refresh-btn');
        const originalText = btn.textContent;
        btn.textContent = "SYNCING...";
        btn.style.opacity = "0.7";

        setTimeout(() => {
            btn.textContent = originalText;
            btn.style.opacity = "1";
            this.updateSensorValues(); // Force update
        }, 1000);
    }

    // ========================================================================
    // 2. VISUALIZATIONS
    // ========================================================================

    initMap() {
        const mapEl = document.getElementById('main-map');
        if (!mapEl) return;

        // Initialize Leaflet Map
        this.map = L.map('main-map', {
            zoomControl: false,
            attributionControl: false
        }).setView([40.7128, -74.0060], 11);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            maxZoom: 19
        }).addTo(this.map);

        const sensorLocations = [
            { lat: 40.7128, lng: -74.0060, type: 'critical' },
            { lat: 40.7589, lng: -73.9851, type: 'warning' },
            { lat: 40.7000, lng: -74.0500, type: 'normal' },
        ];

        sensorLocations.forEach(loc => {
            const color = loc.type === 'critical' ? '#ff2a2a' :
                loc.type === 'warning' ? '#ffaa00' : '#00ff9d';

            L.circleMarker([loc.lat, loc.lng], {
                radius: 6,
                fillColor: color,
                color: "#fff",
                weight: 1,
                opacity: 1,
                fillOpacity: 0.8
            }).addTo(this.map).bindPopup(`SENSOR STATUS: ${loc.type.toUpperCase()}`);
        });

        L.circle([40.7128, -74.0060], {
            color: 'red',
            fillColor: '#f03',
            fillOpacity: 0.2,
            radius: 2000
        }).addTo(this.map);
    }

    initRiskMeter() {
        const ctx = document.getElementById('riskMeter');
        if (!ctx) return;

        this.riskChart = new Chart(ctx.getContext('2d'), {
            type: 'doughnut',
            data: {
                labels: ['Risk', 'Safe'],
                datasets: [{
                    data: [68, 32],
                    backgroundColor: [
                        'rgba(0, 243, 255, 0.8)',
                        'rgba(255, 255, 255, 0.05)'
                    ],
                    borderWidth: 0,
                    circumference: 360,
                    cutout: '85%'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false }, tooltip: { enabled: false } },
                animation: {
                    animateScale: true,
                    animateRotate: true
                }
            }
        });
    }

    // ========================================================================
    // 3. SIMULATION & DATA
    // ========================================================================

    startSensorSimulation() {
        setInterval(() => {
            this.updateSensorValues();
            this.updateRescueUnits();
        }, 3000);

        // Add Search Listener
        const searchInput = document.querySelector('#sensors .neon-input');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.filterSensorTable(e.target.value);
            });
        }
    }

    updateSensorValues() {
        const setVal = (id, base, range, suffix) => {
            const el = document.getElementById(id);
            if (el) {
                const val = (base + (Math.random() * range - range / 2)).toFixed(1);
                el.textContent = val + suffix;
            }
        };

        setVal('val-wave', 2.4, 0.4, 'm');
        setVal('val-water', 4.1, 0.2, 'm');
        setVal('val-wind', 45, 5, 'km/h');

        if (Math.random() > 0.8) {
            const newScore = Math.floor(60 + Math.random() * 20);
            const scoreEl = document.getElementById('risk-score');
            if (scoreEl) scoreEl.textContent = newScore + '%';
            if (this.riskChart) {
                this.riskChart.data.datasets[0].data = [newScore, 100 - newScore];
                this.riskChart.update();
            }
        }
    }

    updateRescueUnits() {
        if (Math.random() > 0.7) {
            const statuses = ['DEPLOYED', 'EN ROUTE', 'STANDBY', 'REFUELING'];
            const units = document.querySelectorAll('.unit-info p:first-of-type');
            if (units.length > 0) {
                const randomUnit = units[Math.floor(Math.random() * units.length)];
                const randomStatus = statuses[Math.floor(Math.random() * statuses.length)];
                randomUnit.textContent = `STATUS: ${randomStatus}`;
            }
        }
    }

    filterSensorTable(query) {
        const rows = document.querySelectorAll('.neon-table tbody tr');
        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            row.style.display = text.includes(query.toLowerCase()) ? '' : 'none';
        });
    }

    startRandomAlerts() {
        setInterval(() => {
            if (Math.random() > 0.7) {
                this.injectRandomAlert();
            }
        }, 8000);
    }

    injectRandomAlert() {
        const alerts = [
            { msg: "WIND SPEED INCREASING - SECTOR 7", type: "warning" },
            { msg: "SENSOR CONNECTION LOST - NODE 4", type: "warning" },
            { msg: "RESCUE TEAM BETA CHECKING IN", type: "info" },
            { msg: "STRUCTURAL VIBRATION DETECTED", type: "critical" }
        ];

        const alert = alerts[Math.floor(Math.random() * alerts.length)];
        const container = document.getElementById('alert-feed');
        if (!container) return;

        const div = document.createElement('div');
        div.className = `alert-item ${alert.type}`;
        div.innerHTML = `
            <div class="alert-time">${new Date().toISOString().split('T')[1].split('.')[0]}</div>
            <div class="alert-msg">${alert.msg}</div>
        `;

        container.insertBefore(div, container.firstChild);
        if (container.children.length > 10) {
            container.removeChild(container.lastChild);
        }
    }
}

// Initialize on Load
document.addEventListener('DOMContentLoaded', () => {
    window.sentinel = new SentinelDashboard();
});
