import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.38.0/+esm';

// ============================================================================
// CONFIGURATION & INITIALIZATION
// ============================================================================

class DisasterManagementDashboard {
    constructor() {
        this.supabaseUrl = localStorage.getItem('supabaseUrl') || '';
        this.supabaseKey = localStorage.getItem('supabaseKey') || '';
        this.refreshInterval = parseInt(localStorage.getItem('refreshInterval')) || 30;
        this.supabase = null;
        this.charts = {};
        this.refreshTimer = null;
        this.initializeApp();
    }

    initializeApp() {
        this.setupEventListeners();
        this.setupNavigation();
        this.checkSupabaseConfig();
        if (this.supabaseUrl && this.supabaseKey) {
            this.initializeSupabase();
        } else {
            this.showNotification('Please configure Supabase credentials in Settings', 'warning');
        }
    }

    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', (e) => {
                e.preventDefault();
                this.switchSection(item.dataset.section);
            });
        });

        // Header buttons
        document.getElementById('refresh-btn').addEventListener('click', () => this.refreshAllData());
        document.getElementById('settings-btn').addEventListener('click', () => this.switchSection('settings'));

        // Settings
        document.getElementById('save-settings-btn').addEventListener('click', () => this.saveSupabaseSettings());
        document.getElementById('save-refresh-btn').addEventListener('click', () => this.saveRefreshSettings());

        // Search and filters
        document.getElementById('buoy-search').addEventListener('input', (e) => this.filterBuoys(e.target.value));
        document.getElementById('buoy-filter').addEventListener('change', (e) => this.filterBuoysByStatus(e.target.value));
        document.getElementById('pole-search').addEventListener('input', (e) => this.filterPoles(e.target.value));
        document.getElementById('pole-filter').addEventListener('change', (e) => this.filterPolesByStatus(e.target.value));

        // Export buttons
        document.getElementById('export-buoy-btn').addEventListener('click', () => this.exportTableToCSV('buoyTable', 'buoy-data'));
        document.getElementById('export-pole-btn').addEventListener('click', () => this.exportTableToCSV('poleTable', 'landslide-data'));

        // Alert section
        document.getElementById('alert-filter').addEventListener('change', (e) => this.filterAlerts(e.target.value));
        document.getElementById('clear-alerts-btn').addEventListener('click', () => this.clearAllAlerts());

        // Modal close button
        const modal = document.getElementById('alert-modal');
        document.querySelector('.close').addEventListener('click', () => {
            modal.style.display = 'none';
        });
        window.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.style.display = 'none';
            }
        });
    }

    setupNavigation() {
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', (e) => {
                e.preventDefault();
                document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
                item.classList.add('active');
                const section = item.dataset.section;
                this.switchSection(section);
            });
        });
    }

    switchSection(sectionId) {
        // Hide all sections
        document.querySelectorAll('.section').forEach(section => {
            section.classList.remove('active');
        });

        // Show selected section
        const section = document.getElementById(sectionId);
        if (section) {
            section.classList.add('active');
            this.updatePageTitle(sectionId);
        }
    }

    updatePageTitle(sectionId) {
        const titles = {
            'dashboard': 'Dashboard Overview',
            'buoy-data': 'Buoy Data Monitoring',
            'landslide-data': 'Landslide Detection Poles',
            'alerts': 'System Alerts',
            'settings': 'System Settings'
        };
        document.getElementById('page-title').textContent = titles[sectionId] || 'Dashboard';
    }

    // ============================================================================
    // SUPABASE INTEGRATION
    // ============================================================================

    initializeSupabase() {
        try {
            this.supabase = createClient(this.supabaseUrl, this.supabaseKey);
            this.loadDashboardData();
            this.setupAutoRefresh();
        } catch (error) {
            console.error('Supabase initialization error:', error);
            this.showNotification('Failed to initialize Supabase. Check your credentials.', 'error');
        }
    }

    saveSupabaseSettings() {
        const url = document.getElementById('supabase-url').value.trim();
        const key = document.getElementById('supabase-key').value.trim();

        if (!url || !key) {
            this.showSettingsMessage('Please fill in all fields', 'error');
            return;
        }

        localStorage.setItem('supabaseUrl', url);
        localStorage.setItem('supabaseKey', key);

        this.supabaseUrl = url;
        this.supabaseKey = key;
        this.initializeSupabase();
        this.showSettingsMessage('Supabase configuration saved successfully!', 'success');
    }

    saveRefreshSettings() {
        const interval = parseInt(document.getElementById('refresh-interval').value);
        if (interval < 5 || interval > 300) {
            this.showNotification('Refresh interval must be between 5 and 300 seconds', 'error');
            return;
        }
        localStorage.setItem('refreshInterval', interval);
        this.refreshInterval = interval;
        this.setupAutoRefresh();
        this.showNotification('Refresh settings saved!', 'success');
    }

    setupAutoRefresh() {
        if (this.refreshTimer) clearInterval(this.refreshTimer);
        this.refreshTimer = setInterval(() => this.refreshAllData(), this.refreshInterval * 1000);
    }

    checkSupabaseConfig() {
        document.getElementById('supabase-url').value = this.supabaseUrl;
        document.getElementById('supabase-key').value = this.supabaseKey;
        document.getElementById('refresh-interval').value = this.refreshInterval;
    }

    // ============================================================================
    // DATA LOADING & PROCESSING
    // ============================================================================

    async loadDashboardData() {
        try {
            await Promise.all([
                this.fetchBuoyData(),
                this.fetchLandslideData(),
                this.generateCharts()
            ]);
            this.updateStats();
        } catch (error) {
            console.error('Error loading dashboard data:', error);
            this.showNotification('Failed to load dashboard data', 'error');
        }
    }

    async fetchBuoyData() {
        try {
            // Try to fetch from Supabase table named 'buoys'
            const { data, error } = await this.supabase.from('buoys').select('*');

            if (error && error.code === 'PGRST116') {
                // Table doesn't exist - use mock data
                this.displayMockBuoyData();
                return;
            }

            if (error) throw error;

            if (data && data.length > 0) {
                this.displayBuoyData(data);
            } else {
                this.displayMockBuoyData();
            }
        } catch (error) {
            console.error('Error fetching buoy data:', error);
            this.displayMockBuoyData();
        }
    }

    async fetchLandslideData() {
        try {
            // Try to fetch from Supabase table named 'landslide_poles'
            const { data, error } = await this.supabase.from('landslide_poles').select('*');

            if (error && error.code === 'PGRST116') {
                // Table doesn't exist - use mock data
                this.displayMockLandslideData();
                return;
            }

            if (error) throw error;

            if (data && data.length > 0) {
                this.displayLandslideData(data);
            } else {
                this.displayMockLandslideData();
            }
        } catch (error) {
            console.error('Error fetching landslide data:', error);
            this.displayMockLandslideData();
        }
    }

    // ============================================================================
    // MOCK DATA (for demonstration)
    // ============================================================================

    displayMockBuoyData() {
        const mockBuoys = [
            {
                id: 'BUOY001',
                location: 'Northern Coast A',
                water_level: 3.2,
                wave_height: 1.8,
                temperature: 22.5,
                status: 'active',
                last_update: new Date().toISOString()
            },
            {
                id: 'BUOY002',
                location: 'Central Bay',
                water_level: 2.8,
                wave_height: 2.1,
                temperature: 21.3,
                status: 'active',
                last_update: new Date().toISOString()
            },
            {
                id: 'BUOY003',
                location: 'Southern Coast',
                water_level: 4.5,
                wave_height: 3.2,
                temperature: 23.1,
                status: 'warning',
                last_update: new Date().toISOString()
            },
            {
                id: 'BUOY004',
                location: 'Eastern Waters',
                water_level: 3.8,
                wave_height: 2.5,
                temperature: 20.8,
                status: 'active',
                last_update: new Date().toISOString()
            }
        ];
        this.displayBuoyData(mockBuoys);
    }

    displayMockLandslideData() {
        const mockPoles = [
            {
                id: 'POLE001',
                location: 'Mountain Ridge A',
                soil_moisture: 65,
                displacement: 2.3,
                temperature: 15.2,
                risk_level: 'low',
                status: 'active',
                last_update: new Date().toISOString()
            },
            {
                id: 'POLE002',
                location: 'Hill Slope B',
                soil_moisture: 78,
                displacement: 5.1,
                temperature: 16.8,
                risk_level: 'warning',
                status: 'active',
                last_update: new Date().toISOString()
            },
            {
                id: 'POLE003',
                location: 'Plateau Region',
                soil_moisture: 45,
                displacement: 1.2,
                temperature: 14.5,
                risk_level: 'low',
                status: 'active',
                last_update: new Date().toISOString()
            },
            {
                id: 'POLE004',
                location: 'Steep Incline C',
                soil_moisture: 85,
                displacement: 12.4,
                temperature: 17.1,
                risk_level: 'critical',
                status: 'warning',
                last_update: new Date().toISOString()
            }
        ];
        this.displayLandslideData(mockPoles);
    }

    // ============================================================================
    // DATA DISPLAY
    // ============================================================================

    displayBuoyData(buoys) {
        this.buoys = buoys;
        const tbody = document.getElementById('buoy-tbody');
        tbody.innerHTML = '';

        buoys.forEach(buoy => {
            const row = document.createElement('tr');
            const lastUpdate = new Date(buoy.last_update).toLocaleString();
            row.innerHTML = `
                <td>${buoy.id}</td>
                <td>${buoy.location}</td>
                <td>${buoy.water_level.toFixed(2)} m</td>
                <td>${buoy.wave_height.toFixed(2)} m</td>
                <td>${buoy.temperature.toFixed(1)}°C</td>
                <td><span class="status-badge status-${buoy.status}">${buoy.status.toUpperCase()}</span></td>
                <td>${lastUpdate}</td>
            `;
            tbody.appendChild(row);
        });
    }

    displayLandslideData(poles) {
        this.poles = poles;
        const tbody = document.getElementById('pole-tbody');
        tbody.innerHTML = '';

        poles.forEach(pole => {
            const row = document.createElement('tr');
            const lastUpdate = new Date(pole.last_update).toLocaleString();
            row.innerHTML = `
                <td>${pole.id}</td>
                <td>${pole.location}</td>
                <td>${pole.soil_moisture.toFixed(1)}%</td>
                <td>${pole.displacement.toFixed(2)} mm</td>
                <td>${pole.temperature.toFixed(1)}°C</td>
                <td><span class="status-badge status-${pole.risk_level}">${pole.risk_level.toUpperCase()}</span></td>
                <td><span class="status-badge status-${pole.status}">${pole.status.toUpperCase()}</span></td>
                <td>${lastUpdate}</td>
            `;
            tbody.appendChild(row);
        });
    }

    // ============================================================================
    // CHARTS & VISUALIZATION
    // ============================================================================

    async generateCharts() {
        // Generate mock data for charts
        const buoys = this.buoys || this.getMockBuoys();
        const poles = this.poles || this.getMockPoles();

        this.createWaterLevelChart(buoys);
        this.createWaveHeightChart(buoys);
        this.createLandslideRiskChart(poles);
        this.createSoilMoistureChart(poles);
    }

    getMockBuoys() {
        return [
            { id: 'BUOY001', location: 'Northern Coast A', water_level: 3.2, wave_height: 1.8 },
            { id: 'BUOY002', location: 'Central Bay', water_level: 2.8, wave_height: 2.1 },
            { id: 'BUOY003', location: 'Southern Coast', water_level: 4.5, wave_height: 3.2 },
            { id: 'BUOY004', location: 'Eastern Waters', water_level: 3.8, wave_height: 2.5 }
        ];
    }

    getMockPoles() {
        return [
            { id: 'POLE001', location: 'Mountain Ridge A', soil_moisture: 65, risk_level: 'low' },
            { id: 'POLE002', location: 'Hill Slope B', soil_moisture: 78, risk_level: 'warning' },
            { id: 'POLE003', location: 'Plateau Region', soil_moisture: 45, risk_level: 'low' },
            { id: 'POLE004', location: 'Steep Incline C', soil_moisture: 85, risk_level: 'critical' }
        ];
    }

    createWaterLevelChart(buoys) {
        const ctx = document.getElementById('waterLevelChart').getContext('2d');
        
        if (this.charts.waterLevel) {
            this.charts.waterLevel.destroy();
        }

        this.charts.waterLevel = new Chart(ctx, {
            type: 'line',
            data: {
                labels: buoys.map(b => b.id),
                datasets: [{
                    label: 'Water Level (m)',
                    data: buoys.map(b => b.water_level),
                    borderColor: '#3b82f6',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 6,
                    pointBackgroundColor: '#3b82f6',
                    pointBorderColor: '#1f2937',
                    pointBorderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        labels: { color: '#f3f4f6', font: { size: 12 } }
                    }
                },
                scales: {
                    y: {
                        grid: { color: '#4b5563' },
                        ticks: { color: '#d1d5db' }
                    },
                    x: {
                        grid: { color: '#4b5563' },
                        ticks: { color: '#d1d5db' }
                    }
                }
            }
        });
    }

    createWaveHeightChart(buoys) {
        const ctx = document.getElementById('waveHeightChart').getContext('2d');
        
        if (this.charts.waveHeight) {
            this.charts.waveHeight.destroy();
        }

        this.charts.waveHeight = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: buoys.map(b => b.id),
                datasets: [{
                    label: 'Wave Height (m)',
                    data: buoys.map(b => b.wave_height),
                    backgroundColor: [
                        'rgba(16, 185, 129, 0.8)',
                        'rgba(59, 130, 246, 0.8)',
                        'rgba(245, 158, 11, 0.8)',
                        'rgba(139, 92, 246, 0.8)'
                    ],
                    borderColor: [
                        '#10b981',
                        '#3b82f6',
                        '#f59e0b',
                        '#8b5cf6'
                    ],
                    borderWidth: 2,
                    borderRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        labels: { color: '#f3f4f6', font: { size: 12 } }
                    }
                },
                scales: {
                    y: {
                        grid: { color: '#4b5563' },
                        ticks: { color: '#d1d5db' }
                    },
                    x: {
                        grid: { color: '#4b5563' },
                        ticks: { color: '#d1d5db' }
                    }
                }
            }
        });
    }

    createLandslideRiskChart(poles) {
        const ctx = document.getElementById('landslideRiskChart').getContext('2d');
        
        if (this.charts.landslideRisk) {
            this.charts.landslideRisk.destroy();
        }

        const riskCounts = {
            low: poles.filter(p => p.risk_level === 'low').length,
            warning: poles.filter(p => p.risk_level === 'warning').length,
            critical: poles.filter(p => p.risk_level === 'critical').length
        };

        this.charts.landslideRisk = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Low Risk', 'Warning', 'Critical'],
                datasets: [{
                    data: [riskCounts.low, riskCounts.warning, riskCounts.critical],
                    backgroundColor: [
                        'rgba(16, 185, 129, 0.8)',
                        'rgba(245, 158, 11, 0.8)',
                        'rgba(239, 68, 68, 0.8)'
                    ],
                    borderColor: [
                        '#10b981',
                        '#f59e0b',
                        '#ef4444'
                    ],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        labels: { color: '#f3f4f6', font: { size: 12 } },
                        position: 'bottom'
                    }
                }
            }
        });
    }

    createSoilMoistureChart(poles) {
        const ctx = document.getElementById('soilMoistureChart').getContext('2d');
        
        if (this.charts.soilMoisture) {
            this.charts.soilMoisture.destroy();
        }

        this.charts.soilMoisture = new Chart(ctx, {
            type: 'radar',
            data: {
                labels: poles.map(p => p.id),
                datasets: [{
                    label: 'Soil Moisture (%)',
                    data: poles.map(p => p.soil_moisture),
                    borderColor: '#8b5cf6',
                    backgroundColor: 'rgba(139, 92, 246, 0.2)',
                    borderWidth: 2,
                    pointRadius: 4,
                    pointBackgroundColor: '#8b5cf6'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        labels: { color: '#f3f4f6', font: { size: 12 } }
                    }
                },
                scales: {
                    r: {
                        grid: { color: '#4b5563' },
                        ticks: { color: '#d1d5db' }
                    }
                }
            }
        });
    }

    // ============================================================================
    // FILTERING & SEARCH
    // ============================================================================

    filterBuoys(searchText) {
        const tbody = document.getElementById('buoy-tbody');
        const rows = tbody.querySelectorAll('tr');
        const searchLower = searchText.toLowerCase();

        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            row.style.display = text.includes(searchLower) ? '' : 'none';
        });
    }

    filterBuoysByStatus(status) {
        const tbody = document.getElementById('buoy-tbody');
        const rows = tbody.querySelectorAll('tr');

        rows.forEach(row => {
            if (status === 'all') {
                row.style.display = '';
            } else {
                const statusCell = row.querySelector('.status-badge');
                const isVisible = statusCell.textContent.toLowerCase().includes(status.toLowerCase());
                row.style.display = isVisible ? '' : 'none';
            }
        });
    }

    filterPoles(searchText) {
        const tbody = document.getElementById('pole-tbody');
        const rows = tbody.querySelectorAll('tr');
        const searchLower = searchText.toLowerCase();

        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            row.style.display = text.includes(searchLower) ? '' : 'none';
        });
    }

    filterPolesByStatus(status) {
        const tbody = document.getElementById('pole-tbody');
        const rows = tbody.querySelectorAll('tr');

        rows.forEach(row => {
            if (status === 'all') {
                row.style.display = '';
            } else {
                const badges = row.querySelectorAll('.status-badge');
                let isVisible = false;
                badges.forEach(badge => {
                    if (badge.textContent.toLowerCase().includes(status.toLowerCase())) {
                        isVisible = true;
                    }
                });
                row.style.display = isVisible ? '' : 'none';
            }
        });
    }

    filterAlerts(severity) {
        const alerts = document.querySelectorAll('.alert-item');
        alerts.forEach(alert => {
            if (severity === 'all') {
                alert.style.display = '';
            } else {
                alert.style.display = alert.classList.contains(severity) ? '' : 'none';
            }
        });
    }

    clearAllAlerts() {
        document.getElementById('alerts-container').innerHTML = '<p class="text-center">No alerts at this time.</p>';
        document.getElementById('alert-count').textContent = '0';
    }

    // ============================================================================
    // EXPORT & UTILITIES
    // ============================================================================

    exportTableToCSV(tableId, filename) {
        const table = document.getElementById(tableId);
        let csv = [];

        // Get headers
        const headers = Array.from(table.querySelectorAll('th')).map(th => th.textContent);
        csv.push(headers.join(','));

        // Get rows
        const rows = table.querySelectorAll('tbody tr');
        rows.forEach(row => {
            const cells = Array.from(row.querySelectorAll('td')).map(td => {
                const text = td.textContent.trim();
                return `"${text.replace(/"/g, '""')}"`;
            });
            csv.push(cells.join(','));
        });

        // Create and download file
        const csvContent = csv.join('\n');
        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `${filename}-${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
    }

    updateStats() {
        document.getElementById('buoy-count').textContent = this.buoys ? this.buoys.length : 0;
        document.getElementById('pole-count').textContent = this.poles ? this.poles.length : 0;
        document.getElementById('alert-count').textContent = document.querySelectorAll('.alert-item').length;
        document.getElementById('system-status').textContent = this.supabase ? 'Operational' : 'Not Connected';
    }

    refreshAllData() {
        if (this.supabase) {
            this.loadDashboardData();
            this.showNotification('Data refreshed successfully!', 'success');
        } else {
            this.showNotification('Supabase not configured. Please check settings.', 'error');
        }
    }

    showNotification(message, type = 'info') {
        console.log(`[${type.toUpperCase()}] ${message}`);
        // You can add a toast notification system here
    }

    showSettingsMessage(message, type) {
        const element = document.getElementById('settings-message');
        element.textContent = message;
        element.className = `settings-message ${type}`;
        element.style.display = 'block';

        setTimeout(() => {
            element.style.display = 'none';
        }, 4000);
    }
}

// ============================================================================
// APPLICATION INITIALIZATION
// ============================================================================

document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new DisasterManagementDashboard();
});
