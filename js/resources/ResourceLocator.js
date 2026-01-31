
export class ResourceLocator {
    constructor(mapInstance) {
        this.map = mapInstance;
        this.currentLocation = null;
        this.markers = [];
        this.resourceLayer = L.layerGroup();
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

    async fetchNearbyResources(filters = []) {
        if (!this.currentLocation) return;

        console.log(`Fetching resources near ${this.currentLocation.lat}, ${this.currentLocation.lng}`);

        // Simulating Overpass API / Google Places API call
        // In a real production app, you would fetch from a backend or OSM Overpass API

        // Mock Data Generator relative to user location
        const mockResources = this.generateMockResources(this.currentLocation.lat, this.currentLocation.lng);

        this.clearResources();

        mockResources.forEach(res => {
            if (filters.length > 0 && !filters.includes(res.type)) return;

            const iconInfo = this.getIconForType(res.type);

            const marker = L.marker([res.lat, res.lng], {
                icon: L.divIcon({
                    className: 'resource-icon-marker',
                    html: `<div style="background:${iconInfo.color}; width:24px; height:24px; border-radius:50%; display:flex; align-items:center; justify-content:center; border:2px solid #fff; box-shadow:0 0 10px ${iconInfo.color}">${iconInfo.emoji}</div>`,
                    iconSize: [24, 24],
                    iconAnchor: [12, 12]
                })
            });

            // Popup with "Get Directions"
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
        });

        console.log(`Loaded ${this.markers.length} resources.`);
    }

    generateMockResources(lat, lng) {
        const types = ['SHELTER', 'HOSPITAL', 'FOOD_BANK', 'WATER_POINT', 'RELIEF_CAMP'];
        const resources = [];

        for (let i = 0; i < 15; i++) {
            // Random offset within ~5-10km
            const latOffset = (Math.random() - 0.5) * 0.08;
            const lngOffset = (Math.random() - 0.5) * 0.08;
            const type = types[Math.floor(Math.random() * types.length)];

            resources.push({
                id: i,
                name: `${type.replace('_', ' ')} ${String.fromCharCode(65 + i)}`,
                type: type,
                lat: lat + latOffset,
                lng: lng + lngOffset,
                distance: this.calculateDistance(lat, lng, lat + latOffset, lng + lngOffset)
            });
        }
        return resources;
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
            case 'HOSPITAL': return { emoji: '🏥', color: '#ff2a2a' }; // Red
            case 'SHELTER': return { emoji: '⛺', color: '#ffaa00' }; // Amber
            case 'FOOD_BANK': return { emoji: '🍲', color: '#00ff9d' }; // Green
            case 'WATER_POINT': return { emoji: '💧', color: '#00f3ff' }; // Blue
            case 'RELIEF_CAMP': return { emoji: '🛡️', color: '#bd68ee' }; // Purple
            default: return { emoji: '📍', color: '#ffffff' };
        }
    }

    updateResourceLayer() {
        this.fetchNearbyResources();
    }

    // External Filter Hook
    applyFilters(activeTypes) {
        this.fetchNearbyResources(activeTypes);
    }
}
