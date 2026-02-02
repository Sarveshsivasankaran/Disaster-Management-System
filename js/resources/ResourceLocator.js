
export class ResourceLocator {
    constructor(mapInstance) {
        this.map = mapInstance;
        this.currentLocation = null;
        this.markers = [];
        this.resourceLayer = L.layerGroup();
        this.setupEventListeners();
    }

    init(lat, lng) {
        this.currentLocation = { lat, lng };
        this.updateResourceLayer();
    }

    addToMap(map) {
        this.resourceLayer.addTo(map);
    }

    clearResources() {
        this.resourceLayer.clearLayers();
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

        console.log(`Fetching resources near ${this.currentLocation.lat}, ${this.currentLocation.lng} with filters:`, filters);

        // use Real Chennai Locations
        const resources = this.getRealResources(this.currentLocation.lat, this.currentLocation.lng);

        this.clearResources();

        const listContainer = document.getElementById('resource-list-container');
        if (listContainer) {
            listContainer.innerHTML = '';
        }

        resources.forEach(res => {
            // Apply Filters (filters empty means show all)
            if (filters.length > 0 && !filters.includes(res.type)) return;

            const iconInfo = this.getIconForType(res.type);

            // 1. Add Marker to Map
            const marker = L.marker([res.lat, res.lng], {
                icon: L.divIcon({
                    className: 'resource-icon-marker',
                    html: `<div style="background:${iconInfo.color}; width:24px; height:24px; border-radius:50%; display:flex; align-items:center; justify-content:center; border:2px solid #fff; box-shadow:0 0 10px ${iconInfo.color}">${iconInfo.emoji}</div>`,
                    iconSize: [24, 24],
                    iconAnchor: [12, 12]
                })
            });

            const popupContent = `
                <div class="resource-popup">
                    <h3 style="margin:0; color:${iconInfo.color}">${res.name}</h3>
                    <p style="margin:5px 0; font-size:0.85em; color:#ccc;">${res.type}</p>
                    <p style="margin:5px 0; font-size:0.9em;">Distance: ${res.distance.toFixed(2)} km</p>
                    <button onclick="window.open('https://www.google.com/maps/dir/?api=1&destination=${res.lat},${res.lng}', '_blank')" 
                        style="background:${iconInfo.color}; color:#000; border:none; padding:5px 10px; border-radius:4px; cursor:pointer; font-weight:bold; width:100%; margin-top:5px;">
                        ↗ GET DIRECTIONS
                    </button>
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
                        <h3>${res.name}</h3>
                        <div class="res-card-meta">
                            <span class="res-type" style="color:${iconInfo.color}">${res.type.replace('_', ' ')}</span>
                            <span class="res-dist">📍 ${res.distance.toFixed(2)} km</span>
                        </div>
                    </div>
                    <button class="res-card-action" onclick="window.sentinel.map.flyTo([${res.lat}, ${res.lng}], 15); document.querySelector('[data-section=\'dashboard\']').click();">
                        MAP VIEW
                    </button>
                `;
                listContainer.appendChild(card);
            }
        });

        if (listContainer && this.markers.length === 0) {
            listContainer.innerHTML = '<div class="no-data">NO RESOURCES FOUND IN THIS CATEGORY</div>';
        }
    }

    getRealResources(uLat, uLng) {
        // Correct Location Mapping for Chennai Area 
        const database = [
            { name: "Rajiv Gandhi Govt General Hospital", type: "HOSPITAL", lat: 13.0827, lng: 80.2753 },
            { name: "Apollo Hospital - Greams Road", type: "HOSPITAL", lat: 13.0605, lng: 80.2520 },
            { name: "Stanley Medical College Hospital", type: "HOSPITAL", lat: 13.1065, lng: 80.2801 },
            { name: "MIOT International Hospital", type: "HOSPITAL", lat: 13.0221, lng: 80.1837 },

            { name: "Nehru Indoor Stadium (Shelter Alpha)", type: "SHELTER", lat: 13.0855, lng: 80.2711 },
            { name: "Chennai Corp Community Center (Shelter)", type: "SHELTER", lat: 13.0566, lng: 80.2582 },
            { name: "Jawaharlal Nehru Stadium Complex", type: "SHELTER", lat: 13.0832, lng: 80.2715 },
            { name: "Anna Nagar Tower Relief Hub", type: "SHELTER", lat: 13.0837, lng: 80.2114 },

            { name: "Chennai Food Bank Central Hub", type: "FOOD_BANK", lat: 13.0645, lng: 80.2645 },
            { name: "No Food Waste Distribution Point", type: "FOOD_BANK", lat: 13.0394, lng: 80.2337 },
            { name: "Akshayapatra Relief Kitchen", type: "FOOD_BANK", lat: 13.1118, lng: 80.2458 },
            { name: "Community Rescue Food Hub", type: "FOOD_BANK", lat: 13.0912, lng: 80.2854 },

            { name: "Kilpauk Water Treatment Plant", type: "WATER_POINT", lat: 13.0829, lng: 80.2427 },
            { name: "Puzhal Water Distribution Main", type: "WATER_POINT", lat: 13.1492, lng: 80.1554 },
            { name: "T.Nagar MetroWater Station", type: "WATER_POINT", lat: 13.0410, lng: 80.2350 },
            { name: "Adyar Regional Water Point", type: "WATER_POINT", lat: 13.0064, lng: 80.2514 }
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
            case 'HOSPITAL': return { emoji: '🏥', color: '#ff2a2a' };
            case 'SHELTER': return { emoji: '⛺', color: '#ffaa00' };
            case 'FOOD_BANK': return { emoji: '🍲', color: '#00ff9d' };
            case 'WATER_POINT': return { emoji: '💧', color: '#00f3ff' };
            default: return { emoji: '📍', color: '#ffffff' };
        }
    }

    updateResourceLayer() {
        this.fetchNearbyResources();
    }

    applyFilters(activeTypes) {
        this.fetchNearbyResources(activeTypes);
    }
}
