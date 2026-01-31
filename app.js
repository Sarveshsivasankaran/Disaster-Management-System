import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.38.0/+esm';
import { SUPABASE_URL, SUPABASE_KEY } from './config.js';
import { ResourceLocator } from './js/resources/ResourceLocator.js';

// ============================================================================
// FUTURISTIC DASHBOARD CONTROLLER
// ============================================================================

class SentinelDashboard {
    constructor() {
        this.supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

        this.map = null;
        this.riskChart = null;
        this.timers = [];
        this.resourceLocator = null; // New Resource Locator

        this.init();
    }

    // ... (init and setups remain)



    init() {
        console.log("SENTINEL: Initializing Systems...");

        // 1. Core UI Setup
        this.setupNavigation();
        this.startRealTimeClock();
        this.setupMapControls();

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
            const options = { timeZone: 'Asia/Kolkata', hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' };
            timeDisplay.textContent = now.toLocaleTimeString('en-IN', options) + " IST";
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
        }).setView([40.7128, -74.0060], 12);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            maxZoom: 19
        }).addTo(this.map);

        // Layer Groups
        this.layers = {
            risk: L.layerGroup().addTo(this.map),
            resources: L.layerGroup(), // Hidden by default, activated on button click
            evac: L.layerGroup(),
            sos: L.layerGroup().addTo(this.map) // Persistent SOS layer
        };
    }

    // --- SOS MARKER MANAGEMENT ---
    clearSOSMarkers() {
        if (this.layers.sos) this.layers.sos.clearLayers();
    }

    restoreSOSMarker(lat, lng, info) {
        if (!this.map || !this.layers.sos) return;
        const sosIcon = L.divIcon({
            className: 'sos-marker',
            html: '🆘',
            iconSize: [30, 30],
            iconAnchor: [15, 15]
        });
        L.marker([lat, lng], { icon: sosIcon })
            .addTo(this.layers.sos)
            .bindPopup(`<b style="color:red">ACTIVE SOS</b><br>${info}`);

        // Initialize Resource Locator
        this.resourceLocator = new ResourceLocator(this.map);
        this.resourceLocator.resourceLayer = this.layers.resources; // Bind to our layer

        this.populateMapLayers(); // Keep structure, but we will make it dynamic
        this.locateUser(); // 1. Realtime User Location
    }

    locateUser() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    const { latitude, longitude } = position.coords;
                    // Store for refreshing
                    this.userLat = latitude;
                    this.userLng = longitude;

                    console.log("LOCATED USER:", latitude, longitude);

                    // Center Map
                    this.map.setView([latitude, longitude], 12);

                    // Add User Marker
                    L.circleMarker([latitude, longitude], {
                        radius: 8,
                        fillColor: '#2979ff',
                        color: "#fff",
                        weight: 3,
                        opacity: 1,
                        fillOpacity: 1
                    }).addTo(this.map).bindPopup("<b>COMMANDER STATUS</b><br>ONLINE - MOBILE HQ");

                    // 2. Fetch Realtime Weather for Location
                    this.fetchLocalWeather(latitude, longitude);

                    // 3. Fetch Realtime Seismic Data (USGS)
                    this.fetchSeismicData(latitude, longitude);

                    // 4. Fetch News & Verify Location
                    this.fetchLocationEvents(latitude, longitude);

                    // 5. Initialize Resource Locator with Real Coords
                    if (this.resourceLocator) {
                        this.resourceLocator.init(latitude, longitude);
                    }

                    // 6. Pre-calculate Evacuation Routes
                    this.populateEvacRoutes(latitude, longitude);
                },
                (err) => {
                    console.warn("Geolocation denied/failed. Using default view.", err);
                    // Fallback: Fetch weather for default view
                    this.userLat = 40.7128;
                    this.userLng = -74.0060;

                    this.fetchLocalWeather(this.userLat, this.userLng);
                    this.fetchSeismicData(this.userLat, this.userLng);
                    this.fetchLocationEvents(this.userLat, this.userLng);
                }
            );
        } else {
            console.warn("Geolocation not supported");
        }
    }

    async fetchLocalWeather(lat, lng) {
        try {
            // Open-Meteo Free API (No Key Required)
            const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}&current_weather=true`;
            const response = await fetch(url);
            const data = await response.json();

            if (data.current_weather) {
                const { temperature, windspeed } = data.current_weather;

                // Add Weather Annotation to Map
                const weatherIcon = L.divIcon({
                    className: 'weather-icon',
                    html: `<div style="background:rgba(0,0,0,0.7); padding:5px; border-radius:4px; color:#fff; font-size:12px; white-space:nowrap;">
                             🌡️ ${temperature}°C <br> 💨 ${windspeed} km/h
                           </div>`
                });

                L.marker([lat + 0.02, lng + 0.02], { icon: weatherIcon }).addTo(this.map);

                // Update Dashboard Cards with REAL DATA
                const tempEl = document.getElementById('val-temp');
                if (tempEl) tempEl.textContent = temperature + "°C";

                const windEl = document.getElementById('val-wind');
                if (windEl) windEl.textContent = windspeed + "km/h";
            }
        } catch (e) {
            console.error("Weather API Error:", e);
        }
    }

    async fetchSeismicData(lat, lng) {
        try {
            // USGS Earthquake API (last 24 hours, 500km radius)
            // Note: Seismic data is sparse. We look for 'events'.
            // If no event, we show low background noise.
            const now = new Date();
            const yesterday = new Date(now.getTime() - (24 * 60 * 60 * 1000)).toISOString();

            const url = `https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&latitude=${lat}&longitude=${lng}&maxradiuskm=500&starttime=${yesterday}&minmagnitude=2`;

            const response = await fetch(url);
            const data = await response.json();

            let gForce = 0.02; // Default background noise
            let status = "QUIET";
            let statusClass = "status-normal";

            if (data.features && data.features.length > 0) {
                // Found a nearby earthquake!
                const quake = data.features[0]; // Most recent
                const mag = quake.properties.mag;

                // Rough simulated acceleration based on magnitude (Just for UI effect, not scientifically precise for 'g')
                gForce = (mag * 0.1).toFixed(2);
                status = `MAG ${mag}`;
                statusClass = mag > 4.5 ? "status-warning" : "status-normal";

                this.injectAlert(`SEISMIC EVENT DETECTED: ${quake.properties.place} (M${mag})`, 'warning');
            }

            // Update UI
            const seisEl = document.getElementById('val-seismic');
            if (seisEl) seisEl.textContent = gForce + "g";

            // Find sibling status element
            if (seisEl && seisEl.nextElementSibling) {
                seisEl.nextElementSibling.textContent = status;
                seisEl.nextElementSibling.className = `sensor-status ${statusClass}`;
            }

        } catch (e) {
            console.error("Seismic API Error:", e);
        }
    }

    async fetchLocationEvents(lat, lng) {
        try {
            // 1. Reverse Geocode to get City Name
            const geoUrl = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lng}&localityLanguage=en`;
            const geoResp = await fetch(geoUrl);
            const geoData = await geoResp.json();

            const city = geoData.city || geoData.locality || "Region";
            const country = geoData.countryName || "";
            this.currentLocationName = `${city}, ${country}`;

            console.log("Resolved Location:", this.currentLocationName);

            // 2. Fetch Flood News for this location
            this.fetchFloodNews(city);

        } catch (e) {
            console.error("Location Service Error:", e);
        }
    }

    async fetchFloodNews(city) {
        try {
            // Google News RSS -> RSS2JSON
            // Query: "Flood {City}"
            const query = encodeURIComponent(`Flood ${city}`);
            const rssUrl = `https://news.google.com/rss/search?q=${query}&hl=en-IN&gl=IN&ceid=IN:en`;
            const apiUrl = `https://api.rss2json.com/v1/api.json?rss_url=${encodeURIComponent(rssUrl)}`;

            const response = await fetch(apiUrl);
            const data = await response.json();

            this.activeFloodNews = [];

            if (data.items && data.items.length > 0) {
                // Filter for very recent/relevant items
                this.activeFloodNews = data.items.slice(0, 3);

                // Notify Dashboard
                const topStory = this.activeFloodNews[0];
                this.injectAlert(`NEWS ALERT: ${topStory.title}`, 'info');

                // Update Risk Verification State
                this.newsRiskVerification = true;
            } else {
                this.newsRiskVerification = false;
            }

        } catch (e) {
            console.error("News API Error:", e);
            this.newsRiskVerification = false;
        }
    }

    setupMapControls() {
        document.querySelectorAll('.map-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const targetBtn = e.target.closest('.map-btn');
                if (!targetBtn) return;

                // Toggle Active State
                document.querySelectorAll('.map-btn').forEach(b => b.classList.remove('active'));
                targetBtn.classList.add('active');

                // Switch Layers
                const layerName = targetBtn.dataset.layer;

                // Hide all EXCEPT SOS (SOS is persistent overlay)
                Object.entries(this.layers).forEach(([key, layer]) => {
                    if (key !== 'sos' && this.map.hasLayer(layer)) {
                        this.map.removeLayer(layer);
                    }
                });

                // Show target
                if (this.layers[layerName]) {
                    this.map.addLayer(this.layers[layerName]);

                    // Trigger refresh if Resources
                    if (layerName === 'resources' && this.resourceLocator) {
                        this.resourceLocator.updateResourceLayer();
                    }

                    // Trigger refresh if Evac
                    if (layerName === 'evac') {
                        this.populateEvacRoutes(this.userLat, this.userLng);
                    }
                }
            });
        });
    }

    async populateMapLayers() {
        // 3. Real Sensor Network from Supabase (Replacing Hardcoded)
        try {
            // Fetch distinct buoy locations (simulated distinct by fetching recent 50 and filtering)
            const { data } = await this.supabase
                .from('buoys')
                .select('id, latitude, longitude, water_level, battery_level')
                .order('created_at', { ascending: false })
                .limit(50);

            if (!data) return;

            // Simple deduplication by ID
            const uniqueSensors = new Map();
            data.forEach(reading => {
                if (!uniqueSensors.has(reading.id)) {
                    uniqueSensors.set(reading.id, reading);
                }
            });

            uniqueSensors.forEach(sensor => {
                // Determine Risk
                let risk = 'low';
                let color = '#00ff9d';
                if (sensor.water_level > 4.0) { risk = 'medium'; color = '#ffaa00'; }
                if (sensor.water_level > 5.5) { risk = 'high'; color = '#ff2a2a'; }

                // Add to Risk Layer
                // Add to Risk Layer
                L.circleMarker([sensor.latitude, sensor.longitude], {
                    radius: 8,
                    fillColor: color,
                    color: "#fff",
                    weight: 2,
                    opacity: 1,
                    fillOpacity: 1
                }).addTo(this.layers.risk).bindPopup(`
                    <b>SENSOR ${sensor.id}</b><br>
                    WATER: ${sensor.water_level}m<br>
                    BATTERY: ${sensor.battery_level}%
                `);
            });

        } catch (e) {
            console.error("Map Data Populate Error:", e);
        }

        // Hardcoded Resources removed in favor of ResourceLocator
    }

    populateEvacRoutes(userLat, userLng) {
        if (!this.layers.evac) return;
        this.layers.evac.clearLayers();

        // Use defaults if location not available
        const lat = userLat || 40.7128;
        const lng = userLng || -74.0060;

        // --- SAFE ROUTES (Green, High Visibility) ---
        const safeRoutes = [
            {
                name: "Main North Corridor (EVAC-1)",
                path: [[lat, lng], [lat + 0.02, lng + 0.01], [lat + 0.05, lng + 0.03]],
                status: 'SAFE'
            },
            {
                name: "West Bridge Route (EVAC-3)",
                path: [[lat, lng], [lat - 0.01, lng - 0.02], [lat - 0.03, lng - 0.05]],
                status: 'SAFE'
            }
        ];

        // --- DANGER ROUTES (Red, Blocked/Flooded) ---
        const unsafeRoutes = [
            {
                name: "Coastal Highway (CLOSED)",
                path: [[lat, lng], [lat + 0.01, lng - 0.03], [lat + 0.02, lng - 0.06]],
                status: 'DANGER',
                reason: 'Severe Flooding Detected'
            }
        ];

        // Draw Safe Paths
        safeRoutes.forEach(route => {
            L.polyline(route.path, {
                color: '#00ff9d',
                weight: 6,
                opacity: 0.8,
                lineJoin: 'round',
                className: 'safe-route-anim'
            }).addTo(this.layers.evac).bindPopup(`
                <div style="text-align:center;">
                    <h4 style="margin:0; color:#00ff9d;">🛡️ ${route.name}</h4>
                    <p style="margin:5px 0; font-weight:bold; color:#00ff9d;">STATUS: SAFE TO TRAVEL</p>
                    <small>Monitored by Sentinel AI</small>
                </div>
            `);
        });

        // Draw Unsafe Paths
        unsafeRoutes.forEach(route => {
            L.polyline(route.path, {
                color: '#ff2a2a',
                weight: 4,
                dashArray: '10, 15',
                opacity: 0.7,
                lineJoin: 'round'
            }).addTo(this.layers.evac).bindPopup(`
                <div style="text-align:center;">
                    <h4 style="margin:0; color:#ff2a2a;">⚠️ ${route.name}</h4>
                    <p style="margin:5px 0; font-weight:bold; color:#ff2a2a;">STATUS: DANGER / BLOCKED</p>
                    <p style="font-size:0.85em;">Reason: ${route.reason}</p>
                </div>
            `);
        });
    }

    updateGeospatialState(reading) {
        // Update Risk Zones based on water level
        if (!this.layers) return;

        // Clear and Re-draw dynamic risk circles if needed, or simple color update
        // For this iteration, we'll update the 'Main' zone (ZN-A) based on live reading
        // assuming reading comes from ZN-A area.

        let riskColor = '#00ff9d'; // Low
        if (reading.water_level > 4.0) riskColor = '#ffaa00'; // Medium
        if (reading.water_level > 5.5) riskColor = '#ff2a2a'; // High

        // We can't easily iterate L.layerGroup children to find specific IDs without custom props.
        // But we can just clear and repopulate 'risk' layer if we want full reacitivty,
        // OR simpler: just add a specific "Live" marker.

        // Let's add a "Live Event" marker to the Risk Layer
        // Remove old live marker if exists
        if (this.liveEventMarker) this.layers.risk.removeLayer(this.liveEventMarker);
        if (this.liveEventRadius) this.layers.risk.removeLayer(this.liveEventRadius);

        const lat = reading.latitude || 40.7128;
        const lng = reading.longitude || -74.0060;

        this.liveEventRadius = L.circle([lat, lng], {
            color: riskColor,
            fillColor: riskColor,
            fillOpacity: 0.2,
            radius: 1500
        }).addTo(this.layers.risk);

        this.liveEventMarker = L.circleMarker([lat, lng], {
            radius: 10,
            fillColor: riskColor,
            color: "#fff",
            weight: 3,
            fillOpacity: 1
        }).addTo(this.layers.risk).bindPopup(`<b>LIVE SENSOR</b><br>WATER: ${reading.water_level}m`);
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
        // Fast updates for database sensors (3s)
        setInterval(() => {
            this.updateSensorValues();
            this.updateRescueUnits();
        }, 3000);

        // Slow updates for External APIs (5 mins)
        setInterval(() => {
            if (this.userLat && this.userLng) {
                console.log("Refreshing External APIs...");
                this.fetchLocalWeather(this.userLat, this.userLng);
                this.fetchSeismicData(this.userLat, this.userLng);
                this.fetchLocationEvents(this.userLat, this.userLng);
            }
        }, 5 * 60 * 1000);

        // Add Search Listener
        const searchInput = document.querySelector('#sensors .neon-input');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.filterSensorTable(e.target.value);
            });
        }
    }

    async updateSensorValues() {
        try {
            const { data, error } = await this.supabase
                .from('buoys')
                .select('*')
                .order('created_at', { ascending: false })
                .limit(10);

            if (data && data.length > 0) {
                const reading = data[0];
                const riskScore = this.calculateRisk(reading);

                this.updateDashboardCards(reading);
                this.updateGeospatialState(reading); // Updated Map Logic
                this.updateRiskDisplay(riskScore);
                this.checkThresholds(reading);
                this.updateHistoryTable(data);

                this.updateEvacuationRoutes(reading.water_level);
                this.updateRescueStatus(riskScore);
                this.updateEvacuationRoutes(reading.water_level);
                this.updateRescueStatus(riskScore);
                this.updateAnalysis(reading, riskScore, data);
            }
        } catch (err) {
            console.error("Supabase Fetch Error:", err);
        }
        this.simulateMissingSensors();
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
            <div class="alert-time">${new Date().toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata', hour12: false })}</div>
            <div class="alert-msg">${alert.msg}</div>
        `;

        container.insertBefore(div, container.firstChild);
        if (container.children.length > 10) {
            container.removeChild(container.lastChild);
        }
    }

    // --- Helper Methods ---
    updateDashboardCards(reading) {
        const setVal = (id, val, suffix) => {
            const el = document.getElementById(id);
            if (el) el.textContent = val + suffix;
        };
        setVal('val-wave', reading.wave_height.toFixed(2), 'm');
        setVal('val-water', reading.water_level.toFixed(2), 'm');
        setVal('val-temp', reading.temperature.toFixed(1), '°C');
        setVal('val-bat', reading.battery_level, '%');
    }



    calculateRisk(reading) {
        const waveRisk = Math.min((reading.wave_height / 5) * 50, 50);
        const waterRisk = Math.min((reading.water_level / 8) * 50, 50);
        return Math.floor(waveRisk + waterRisk);
    }

    updateRiskDisplay(score) {
        const scoreEl = document.getElementById('risk-score');
        if (scoreEl) scoreEl.textContent = score + '%';
        if (this.riskChart) {
            this.riskChart.data.datasets[0].data = [score, 100 - score];
            let color = '#00f3ff';
            if (score > 40) color = '#ffaa00';
            if (score > 75) color = '#ff2a2a';
            this.riskChart.data.datasets[0].backgroundColor[0] = color;
            this.riskChart.update();
        }
    }

    checkThresholds(reading) {
        if (reading.water_level > 5.5) this.injectAlert(`CRITICAL FLOOD LEVEL: ${reading.water_level.toFixed(2)}m`, 'critical');
        else if (reading.water_level > 4.0) this.injectAlert(`RISING WATER LEVEL: ${reading.water_level.toFixed(2)}m`, 'warning');
        if (reading.wave_height > 3.0) this.injectAlert(`HIGH WAVE ALERT: ${reading.wave_height.toFixed(2)}m`, 'warning');
    }

    updateHistoryTable(dataRows) {
        const tbody = document.querySelector('.neon-table tbody');
        if (!tbody) return;
        tbody.innerHTML = '';
        dataRows.forEach(row => {
            const tr = document.createElement('tr');
            let status = 'NORMAL';
            let statusClass = 'normal';
            if (row.water_level > 4.0) { status = 'HIGH'; statusClass = 'warning'; }
            if (row.water_level > 5.5) { status = 'CRITICAL'; statusClass = 'critical'; }

            const timeStr = new Date(row.created_at).toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata' });

            tr.innerHTML = `
                <td><span class="highlight-blue">${row.id}</span></td>
                <td>${row.location || 'Unknown'}</td>
                <td>SENSOR DATA</td>
                <td>${row.water_level.toFixed(2)}m</td>
                <td><span class="status-badge ${statusClass}">${status}</span></td>
                <td>${timeStr}</td>
            `;
            tbody.appendChild(tr);
        });
    }

    updateEvacuationRoutes(waterLevel) {
        const routeCards = document.querySelectorAll('.route-card');
        if (routeCards.length < 2) return;
        const routeA = routeCards[0];
        const routeB = routeCards[1];

        if (waterLevel > 5.0) this.setRouteStatus(routeA, 'BLOCKED', 'FLOODED - DO NOT USE', 'danger');
        else this.setRouteStatus(routeA, 'CLEAR', 'CAPACITY: 85% AVAILABLE', 'safe');

        if (waterLevel > 3.5) this.setRouteStatus(routeB, 'BLOCKED', 'COASTAL FLOODING', 'danger');
        else {
            this.setRouteStatus(routeB, 'CLEAR', 'CAPACITY: 40% AVAILABLE', 'warning');
            if (waterLevel < 3.5) routeB.className = 'route-card safe';
        }
    }

    setRouteStatus(card, badgeText, statusText, type) {
        card.className = `route-card ${type}`;
        const badge = card.querySelector('.badge');
        if (badge) {
            badge.className = `badge ${type === 'danger' ? 'danger' : 'success'}`;
            badge.textContent = badgeText;
        }
        const pTags = card.querySelectorAll('p');
        if (pTags.length > 0) pTags[0].textContent = statusText;
    }

    updateRescueStatus(riskScore) {
        const status = riskScore > 60 ? 'DEPLOYED' : 'STANDBY';
        const units = document.querySelectorAll('.unit-info');
        units.forEach(unit => {
            const statusEl = unit.querySelector('p:first-of-type');
            if (statusEl) statusEl.textContent = `STATUS: ${status}`;
        });
    }

    updateAnalysis(reading, riskScore, historyData) {
        // 1. Calculate Trend (Slope)
        let trend = 0; // meters per hour
        if (historyData && historyData.length > 1) {
            const latest = historyData[0];
            const oldest = historyData[historyData.length - 1];

            const timeSpanHours = (new Date(latest.created_at) - new Date(oldest.created_at)) / (1000 * 60 * 60);

            if (timeSpanHours > 0) {
                trend = (latest.water_level - oldest.water_level) / timeSpanHours;
            }
        }

        // 2. Project Future Levels (Current, +1h, +3h, +6h, +12h)
        const timeSteps = [0, 1, 3, 6, 12];
        const maxLevel = 10; // Max graph scale in meters

        const bars = document.querySelectorAll('.bar-chart-visual .bar');
        bars.forEach((bar, index) => {
            if (index >= timeSteps.length) return;

            const hours = timeSteps[index];
            const projectedLevel = reading.water_level + (trend * hours);
            let heightPercent = Math.min(100, Math.max(0, (projectedLevel / maxLevel) * 100));

            // Visual Styling
            bar.style.height = `${heightPercent}%`;
            bar.className = 'bar'; // Reset

            if (projectedLevel > 5.5) bar.classList.add('warning'); // Critical
            else if (hours === 0) bar.style.backgroundColor = '#00f3ff'; // Current
            else bar.style.backgroundColor = 'rgba(0, 243, 255, 0.3)'; // Future

            // Optional: Add simple tooltip logic or label if needed
            bar.title = `+${hours}h: ${projectedLevel.toFixed(2)}m`;
        });

        // 3. Update Text Label (With News Verification)
        const chartLabel = document.querySelector('.chart-label');
        if (chartLabel) {
            const trendText = Math.abs(trend) < 0.05 ? "STABLE" :
                (trend > 0 ? `RISING (+${trend.toFixed(2)}m/h)` : `RECEDING (${trend.toFixed(2)}m/h)`);

            let verificationText = "";
            let confidence = "86%"; // Default AI Confidence

            if (this.newsRiskVerification && trend > 0) {
                verificationText = `<br><span class="highlight-red">⚠ VERIFIED BY LOCAL NEWS REPORTS</span>`;
                confidence = "98%"; // Boost confidence
            } else if (Math.abs(trend) > 0.1) {
                verificationText = `<br><span class="highlight-blue">⚠ SENSOR TREND DETECTED</span>`;
            }

            chartLabel.innerHTML = `PROJECTED LEVELS (NEXT 12H) <br> <span style="color:${trend > 0 ? '#ffaa00' : '#00ff9d'}">${trendText}</span>${verificationText}`;

            // Update Confidence UI
            const confEl = document.querySelector('.ai-stats .stat-row:first-child .highlight-blue');
            if (confEl) confEl.textContent = confidence;
        }

        // 4. Update Structural Integrity Metric
        const fill = document.querySelector('.stat-item .fill');
        const val = document.querySelector('.stat-item .val');
        if (fill) fill.style.width = `${Math.max(0, 100 - riskScore)}%`;
        if (val) val.textContent = `${Math.max(0, 100 - riskScore)}%`;
    }

    simulateMissingSensors() {
        // No longer needed as we fetch real data for all sensors now.
        // Keeping method stub to prevent errors if referenced.
    }

    injectAlert(msg, type) {
        const container = document.getElementById('alert-feed');
        if (!container) return;
        if (container.firstChild && container.firstChild.innerHTML.includes(msg)) return;

        const div = document.createElement('div');
        div.className = `alert-item ${type}`;
        div.innerHTML = `
            <div class="alert-time">${new Date().toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata', hour12: false })}</div>
            <div class="alert-msg">${msg}</div>
        `;
        container.insertBefore(div, container.firstChild);
        if (container.children.length > 20) container.removeChild(container.lastChild);
    }

    deployRescueToLocation(lat, lng, info) {
        if (!this.map) return;

        console.log(`DEPLOYING RESCUE TO: ${lat}, ${lng}`);

        // 1. Mark SOS Location
        const sosIcon = L.divIcon({
            className: 'sos-marker',
            html: '🆘',
            iconSize: [30, 30],
            iconAnchor: [15, 15]
        });

        const marker = L.marker([lat, lng], { icon: sosIcon }).addTo(this.layers.sos)
            .bindPopup(`<b style="color:red">EMERGENCY SOS</b><br>${info}`).openPopup();

        // 2. Find closest resource (Simulated for fixed resources)
        // In a real app, calculate distance to this.layers.resources children
        const baseLat = 40.7300;
        const baseLng = -74.0100;

        // 3. Draw Route Line
        const routeLine = L.polyline([[baseLat, baseLng], [lat, lng]], {
            color: '#ff2a2a',
            weight: 4,
            dashArray: '10, 10',
            className: 'rescue-route-anim'
        }).addTo(this.map);

        // 4. Send Alert
        this.injectAlert(`RESCUE UNIT DEPLOYED TO SOS: ${info}`, 'critical');

        // 5. Update Rescue Panel Numbers
        const activeUnitsEl = document.querySelector('.rescue-panel .big-value');
        if (activeUnitsEl) {
            let current = parseInt(activeUnitsEl.textContent) || 0;
            activeUnitsEl.textContent = current + 1;
        }

        // Auto Switch to Map View if not already
        // document.querySelector('[data-section="dashboard"]').click();
        this.map.flyTo([lat, lng], 14);

        // cleanup after some time?
        setTimeout(() => {
            this.map.removeLayer(routeLine);
        }, 30000);
    }
}

// Initialize on Load
document.addEventListener('DOMContentLoaded', () => {
    window.sentinel = new SentinelDashboard();
});
