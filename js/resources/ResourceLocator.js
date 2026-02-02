
export class ResourceLocator {
    constructor(mapInstance) {
        this.map = mapInstance;
        this.currentLocation = null;
        this.markers = [];
        this.resourceLayer = L.layerGroup();
        this.setupEventListeners();
        this.routingLayer = L.layerGroup();
    }

    init(lat, lng) {
        this.currentLocation = { lat, lng };
        this.updateResourceLayer();
    }

    addToMap(map) {
        this.resourceLayer.addTo(map);
        this.routingLayer.addTo(map);
    }

    clearResources() {
        this.resourceLayer.clearLayers();
        this.routingLayer.clearLayers();
        this.markers = [];
    }

    setupEventListeners() {
        // Listen for filter clicks on the Resources section
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('res-filter')) {
                const type = e.target.dataset.type;

                // Update active button state
                document.querySelectorAll('.res-filter').forEach(btn => btn.classList.remove('active'));
                e.target.classList.add('active');

                // Filter logic
                if (type === 'ALL') {
                    this.fetchNearbyResources([]);
                } else {
                    this.fetchNearbyResources([type]);
                }
            }
        });
    }

    async fetchNearbyResources(filters = []) {
        if (!this.currentLocation) return;

        console.log(`SENTINEL: Fetching dynamic resources near ${this.currentLocation.lat}, ${this.currentLocation.lng}`);

        const lat = this.currentLocation.lat;
        const lng = this.currentLocation.lng;
        const radius = 5000; // 5km

        const query = `
            [out:json];
            (
                nwr["amenity"~"hospital|police|fire_station|shelter|pharmacy|clinic|community_centre|school|place_of_worship"](around:${radius},${lat},${lng});
                nwr["tourism"="hotel"](around:${radius},${lat},${lng});
                nwr["emergency"="social_facility"](around:${radius},${lat},${lng});
            );
            out center;
        `;

        try {
            const url = `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(query)}`;
            const response = await fetch(url);

            if (!response.ok) throw new Error("OSM API Error");

            const data = await response.json();
            const elements = data.elements || [];

            let resources = elements.map(el => {
                const tags = el.tags || {};
                const name = tags.name || tags.brand || "Emergency Facility";
                const amenity = (tags.amenity || tags.tourism || "RESOURCE").toLowerCase();

                let resType = "RESOURCE";
                if (amenity.includes('hospital') || amenity.includes('clinic') || amenity.includes('pharmacy') || amenity.includes('doctors')) resType = "HOSPITAL";
                else if (amenity.includes('shelter') || amenity.includes('hotel') || amenity.includes('community_centre') || amenity.includes('school') || amenity.includes('worship')) resType = "SHELTER";
                else if (amenity.includes('police')) resType = "POLICE";
                else if (amenity.includes('fire')) resType = "FIRE_STATION";

                const resLat = el.lat || (el.center ? el.center.lat : null);
                const resLng = el.lon || (el.center ? el.center.lon : null);

                if (!resLat || !resLng) return null;

                return {
                    name,
                    type: resType,
                    lat: resLat,
                    lng: resLng,
                    distance: this.calculateDistance(lat, lng, resLat, resLng)
                };
            }).filter(r => r !== null);

            if (resources.length === 0) {
                resources = this.getFallbackResources(lat, lng);
            }

            this.renderResources(resources, filters);

        } catch (e) {
            console.warn("SENTINEL: Overpass API failed, using fallback database.", e);
            const resources = this.getFallbackResources(lat, lng);
            this.renderResources(resources, filters);
        }
    }

    renderResources(resources, filters) {
        this.clearResources();

        const listContainer = document.getElementById('resource-list-container');
        if (listContainer) {
            listContainer.innerHTML = '';
        }

        resources.forEach(res => {
            // Apply Filters
            if (filters.length > 0 && !filters.includes(res.type)) return;

            const iconInfo = this.getIconForType(res.type);

            // 1. Add Marker to Map
            const marker = L.marker([res.lat, res.lng], {
                icon: L.divIcon({
                    className: 'resource-icon-marker',
                    html: `<div style="background:${iconInfo.color}; width:28px; height:28px; border-radius:50%; display:flex; align-items:center; justify-content:center; border:2px solid #fff; box-shadow:0 0 15px ${iconInfo.color}">${iconInfo.emoji}</div>`,
                    iconSize: [28, 28],
                    iconAnchor: [14, 14]
                })
            });

            const popupContent = `
                <div class="resource-popup" style="min-width:200px; font-family:'Rajdhani', sans-serif;">
                    <h3 style="margin:0; color:${iconInfo.color}; font-family:'Orbitron'; font-size:14px;">${res.name}</h3>
                    <p style="margin:5px 0; font-size:0.85em; color:#00ff9d; font-weight:bold;">${res.type.replace('_', ' ')}</p>
                    <p style="margin:5px 0; font-size:0.9em; color:#fff;">📍 DISTANCE: ${res.distance.toFixed(2)} km</p>
                    <div style="display:flex; gap:5px; margin-top:10px;">
                        <button onclick="window.sentinel.resourceLocator.calculateRoute(${res.lat}, ${res.lng}, '${res.name.replace(/'/g, "\\'")}')" 
                            style="background:#00ff9d; color:#000; border:none; padding:8px; border-radius:4px; cursor:pointer; font-weight:bold; flex:1; font-size:10px;">
                            ROUTE
                        </button>
                        <button onclick="window.open('https://www.google.com/maps/dir/?api=1&destination=${res.lat},${res.lng}', '_blank')" 
                            style="background:rgba(255,255,255,0.1); color:#fff; border:1px solid #fff; padding:8px; border-radius:4px; cursor:pointer; flex:1; font-size:10px;">
                            GMAPS
                        </button>
                    </div>
                </div>
            `;

            marker.bindPopup(popupContent);
            this.resourceLayer.addLayer(marker);
            this.markers.push(marker);

            // 2. Add to Resource List
            if (listContainer) {
                const card = document.createElement('div');
                card.className = 'resource-card-item glass-panel';
                card.innerHTML = `
                    <div class="res-card-icon" style="background:${iconInfo.color}15; color:${iconInfo.color}">${iconInfo.emoji}</div>
                    <div class="res-card-info">
                        <h3 style="font-family:'Orbitron'; font-size:12px;">${res.name}</h3>
                        <div class="res-card-meta">
                            <span class="res-type" style="color:${iconInfo.color}">${res.type.replace('_', ' ')}</span>
                            <span class="res-dist">📍 ${res.distance.toFixed(2)} km</span>
                        </div>
                    </div>
                    <button class="res-card-action" onclick="window.sentinel.map.flyTo([${res.lat}, ${res.lng}], 15); window.sentinel.resourceLocator.calculateRoute(${res.lat}, ${res.lng}, '${res.name.replace(/'/g, "\\'")}')">
                        ROUTE
                    </button>
                `;
                listContainer.appendChild(card);
            }
        });

        if (listContainer && this.markers.length === 0) {
            listContainer.innerHTML = '<div class="no-data">NO RESOURCES FOUND IN THIS CATEGORY</div>';
        }
    }

    async calculateRoute(destLat, destLng, name) {
        if (!this.currentLocation) return;
        this.routingLayer.clearLayers();

        const start = this.currentLocation;
        const osrmUrl = `https://router.project-osrm.org/route/v1/driving/${start.lng},${start.lat};${destLng},${destLat}?overview=full&geometries=geojson`;

        try {
            const resp = await fetch(osrmUrl);
            const data = await resp.json();

            if (data.routes && data.routes.length > 0) {
                const route = L.geoJSON(data.routes[0].geometry, {
                    style: {
                        color: '#00ff9d',
                        weight: 6,
                        opacity: 0.8,
                        className: 'safe-route-anim'
                    }
                }).addTo(this.routingLayer);

                // Add end marker
                L.circleMarker([destLat, destLng], {
                    radius: 6,
                    color: '#00ff9d',
                    fillOpacity: 1
                }).addTo(this.routingLayer).bindTooltip(`NAVIGATING TO ${name}`, { permanent: true, direction: 'top' });

                // Switch to dashboard view if not already there
                const dashboardNav = document.querySelector('[data-section="dashboard"]');
                if (dashboardNav && !dashboardNav.classList.contains('active')) {
                    dashboardNav.click();
                }

                // Invalidate map size to ensure rendering
                setTimeout(() => this.map.invalidateSize(), 300);

                // Switch to resources map layer
                const resMapBtn = document.querySelector('[data-layer="resources"]');
                if (resMapBtn) resMapBtn.click();

            }
        } catch (e) {
            console.error("Routing Error:", e);
        }
    }

    getFallbackResources(uLat, uLng) {
        const database = [
            { name: "Global Relief Hospital", type: "HOSPITAL", lat: uLat + 0.005, lng: uLng + 0.005 },
            { name: "Emergency Shelter Zone A", type: "SHELTER", lat: uLat - 0.008, lng: uLng + 0.002 },
            { name: "Food Distribution Point", type: "FOOD_BANK", lat: uLat + 0.012, lng: uLng - 0.005 }
        ];

        return database.map(res => ({
            ...res,
            distance: this.calculateDistance(uLat, uLng, res.lat, res.lng)
        })).sort((a, b) => a.distance - b.distance);
    }

    calculateDistance(lat1, lon1, lat2, lon2) {
        const R = 6371; // km
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLon = (lon2 - lon1) * Math.PI / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    getIconForType(type) {
        switch (type) {
            case 'HOSPITAL': return { emoji: '🚑', color: '#ff2727' };
            case 'SHELTER': return { emoji: '⛺', color: '#ffaa00' };
            case 'FOOD_BANK': return { emoji: '🍲', color: '#00ff9d' };
            case 'WATER_POINT': return { emoji: '💧', color: '#00f3ff' };
            case 'POLICE': return { emoji: '🚔', color: '#2979ff' };
            case 'FIRE_STATION': return { emoji: '🚒', color: '#ff5722' };
            default: return { emoji: '📍', color: '#ffffff' };
        }
    }

    updateResourceLayer() {
        this.fetchNearbyResources();
    }
}
