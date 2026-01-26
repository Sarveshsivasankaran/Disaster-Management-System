# Project Structure & File Guide

## 📁 Project Files Overview

```
Disaster-Management-System/
├── index.html              # Main dashboard HTML (UI structure)
├── styles.css              # Complete styling & responsive design
├── app.js                  # JavaScript logic & Supabase integration
├── config.json             # Configuration template
├── database-setup.sql      # Database initialization script
├── README.md               # Full documentation
├── QUICKSTART.md           # 5-minute setup guide
├── DEPLOYMENT.md           # Deployment & production guide
├── PROJECT-STRUCTURE.md    # This file
└── .git/                   # Git repository

```

## 📄 File Descriptions

### Core Application Files

#### **index.html** (1000+ lines)
**Purpose**: Main HTML structure for the dashboard

**Key Sections**:
- Sidebar navigation with 5 main sections
- Statistics cards display
- Chart containers (4 different chart types)
- Data tables for buoys and landslide poles
- Alerts management section
- Settings/configuration section
- Modal for alert details

**Navigation Items**:
- 📊 Dashboard (overview with stats and charts)
- 🌊 Buoy Data (table with search/filter/export)
- ⛰️ Landslide Detection (pole monitoring)
- 🚨 Alerts (system notifications)
- ⚙️ Settings (Supabase configuration)

#### **styles.css** (1400+ lines)
**Purpose**: Complete styling and responsive design

**Key Sections**:
- CSS variables for theme colors (dark mode)
- Layout: Sidebar + Main content
- Component styling (cards, tables, buttons, forms)
- Chart styling (dark theme compatible)
- Responsive media queries (tablet, mobile)
- Animations and transitions
- Scrollbar customization

**Theme Colors**:
- Primary: Blue (#2563eb)
- Success: Green (#10b981)
- Danger: Red (#ef4444)
- Warning: Amber (#f59e0b)
- Dark backgrounds for optimal contrast

#### **app.js** (1300+ lines)
**Purpose**: Application logic and Supabase integration

**Main Classes**:
- `DisasterManagementDashboard`: Main application class

**Key Features**:
```javascript
// Core Methods
initializeApp()           // Initialize dashboard
initializeSupabase()      // Connect to Supabase
loadDashboardData()       // Fetch all data
fetchBuoyData()          // Get buoy data from Supabase
fetchLandslideData()     // Get landslide pole data

// Chart Methods
generateCharts()         // Create all 4 charts
createWaterLevelChart()  // Line chart
createWaveHeightChart()  // Bar chart
createLandslideRiskChart() // Doughnut chart
createSoilMoistureChart() // Radar chart

// Data Display
displayBuoyData()        // Render buoy table
displayLandslideData()   // Render pole table
displayMockBuoyData()    // Fallback data
displayMockLandslideData() // Fallback data

// Filtering & Search
filterBuoys()            // Search buoy data
filterBuoysByStatus()    // Filter by status
filterPoles()            // Search pole data
filterPolesByStatus()    // Filter by status
filterAlerts()           // Filter alerts by severity

// Utilities
exportTableToCSV()       // Export data
updateStats()            // Update stat cards
refreshAllData()         // Manual refresh
showNotification()       // Display messages
```

### Configuration Files

#### **config.json** (100+ lines)
**Purpose**: Dashboard configuration template

**Sections**:
- Dashboard metadata
- Supabase connection settings
- Database table schemas
- Refresh settings
- Chart configurations
- Theme color definitions
- Status/risk level options
- Feature flags

**Usage**: Reference for expected structure and available options

#### **database-setup.sql** (300+ lines)
**Purpose**: Database initialization and setup

**Includes**:
```sql
-- Table Creation
CREATE TABLE buoys (...)
CREATE TABLE landslide_poles (...)
CREATE TABLE alerts (...)
CREATE TABLE system_logs (...)

-- Indexes (for performance)
CREATE INDEX idx_buoy_status ON buoys(status);
CREATE INDEX idx_pole_risk ON landslide_poles(risk_level);
...

-- Sample Data (for testing)
INSERT INTO buoys VALUES (...)
INSERT INTO landslide_poles VALUES (...)
INSERT INTO alerts VALUES (...)

-- Views (for dashboard queries)
CREATE VIEW v_buoy_summary AS ...
CREATE VIEW v_landslide_summary AS ...
CREATE VIEW v_recent_alerts AS ...

-- Functions & Triggers (automatic updates)
CREATE FUNCTION update_buoy_timestamp() ...
CREATE TRIGGER trigger_update_buoy_timestamp ...

-- Permissions
GRANT SELECT ON buoys TO anon;
...
```

### Documentation Files

#### **README.md** (400+ lines)
**Purpose**: Complete project documentation

**Contents**:
- Feature overview
- Tech stack information
- Setup instructions (step-by-step)
- Usage guide
- Architecture documentation
- Browser compatibility
- Performance features
- Troubleshooting guide
- Customization options
- Security notes
- Future enhancements
- Support resources

#### **QUICKSTART.md** (200+ lines)
**Purpose**: Fast setup for new users

**Contents**:
- 5-minute setup steps
- Supabase credential setup
- Database table creation
- Sample data insertion
- Dashboard configuration
- Feature explanations
- Common tasks
- Customization tips
- Troubleshooting quick fixes
- Production checklist

#### **DEPLOYMENT.md** (300+ lines)
**Purpose**: Production deployment guide

**Contents**:
- Local development setup
- GitHub Pages deployment
- Vercel deployment
- Netlify deployment
- Self-hosted VPS setup
- Security best practices
- CORS configuration
- HTTPS/SSL setup
- Monitoring & maintenance
- Database optimization
- Scaling considerations
- CI/CD pipeline setup
- Rollback procedures
- Pre-launch checklist

## 🔄 Data Flow Architecture

```
┌─────────────────┐
│   User Browser  │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  index.html     │◄── Loads styles.css & app.js
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   styles.css    │ Renders UI
└─────────────────┘

┌─────────────────┐
│    app.js       │◄── Event listeners & logic
│ (Supabase SDK)  │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│    Supabase     │◄── PostgreSQL
│   (Fetch API)   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   Display Data  │
│ - Tables        │
│ - Charts        │
│ - Stats         │
└─────────────────┘
```

## 🎯 Key Features Implementation

### Feature: Real-time Data Display
**Files Involved**: app.js, index.html
```javascript
// Fetch from Supabase
const { data, error } = await this.supabase.from('buoys').select('*');
// Display in table
this.displayBuoyData(data);
// Render charts
this.createWaterLevelChart(data);
```

### Feature: Search & Filter
**Files Involved**: app.js, styles.css
```javascript
filterBuoys(searchText) {
  // Filter table rows based on search input
  // Update display in real-time
}
```

### Feature: Data Export
**Files Involved**: app.js, index.html
```javascript
exportTableToCSV(tableId, filename) {
  // Convert table to CSV
  // Trigger download
}
```

### Feature: Auto-Refresh
**Files Involved**: app.js
```javascript
setupAutoRefresh() {
  // Set interval from settings
  // Fetch data periodically
  // Update charts automatically
}
```

## 🗄️ Database Schema

### Buoys Table
```
id (TEXT PRIMARY KEY)
location (VARCHAR)
latitude (DECIMAL)
longitude (DECIMAL)
water_level (DECIMAL)
wave_height (DECIMAL)
temperature (DECIMAL)
status (VARCHAR)
battery_level (INT)
signal_strength (INT)
last_update (TIMESTAMP)
created_at (TIMESTAMP)
```

### Landslide Poles Table
```
id (TEXT PRIMARY KEY)
location (VARCHAR)
latitude (DECIMAL)
longitude (DECIMAL)
soil_moisture (DECIMAL)
displacement (DECIMAL)
temperature (DECIMAL)
risk_level (VARCHAR)
status (VARCHAR)
battery_level (INT)
signal_strength (INT)
last_update (TIMESTAMP)
created_at (TIMESTAMP)
```

### Alerts Table
```
id (UUID PRIMARY KEY)
title (VARCHAR)
message (TEXT)
severity (VARCHAR)
source_type (VARCHAR)
source_id (TEXT)
is_resolved (BOOLEAN)
created_at (TIMESTAMP)
resolved_at (TIMESTAMP)
```

## 📊 Chart Types Used

| Chart | File | Purpose | Data Source |
|-------|------|---------|-------------|
| Line Chart | app.js | Water level trends | Buoy data |
| Bar Chart | app.js | Wave height comparison | Buoy data |
| Doughnut Chart | app.js | Risk distribution | Landslide poles |
| Radar Chart | app.js | Soil moisture levels | Landslide poles |

## 🎨 CSS Organization

```css
:root                    /* Color variables */
body                     /* Global styles */
.container              /* Main layout container */
.sidebar                /* Left navigation */
.main-content           /* Right content area */
.stats-grid             /* Statistics cards */
.charts-grid            /* Chart containers */
.data-table             /* Data tables */
.filters                /* Search/filter UI */
.settings-card          /* Settings forms */
.modal                  /* Modal dialogs */
@media (tablet/mobile)  /* Responsive design */
```

## 🔐 Security Considerations

**Stored in Browser**:
- Supabase URL (public)
- Supabase API Key (public/anon key only)

**Never Store**:
- Service role keys
- Database passwords
- User credentials

**Production Security**:
- Use Row Level Security (RLS)
- Implement authentication
- Use environment variables
- Enable HTTPS
- Set CORS properly

## 🚀 Performance Optimization

**Current Optimizations**:
- Lazy loading of charts
- Client-side filtering
- Efficient DOM updates
- CSS grid/flexbox
- Responsive images
- Optimized assets

**Potential Improvements**:
- Pagination for large datasets
- Virtual scrolling for tables
- Service Worker caching
- Minified assets
- CDN for static files

## 📱 Responsive Breakpoints

```css
Desktop:   1024px and up
Tablet:    768px to 1024px
Mobile:    480px to 768px
Small:     Below 480px
```

## 🔄 Workflow

### Development
1. Edit HTML/CSS/JS locally
2. Test in browser (F12 DevTools)
3. Use local server (http-server)
4. Check console for errors

### Testing
1. Verify all sections load
2. Test search/filter
3. Check chart rendering
4. Test export functionality
5. Verify responsive design

### Deployment
1. Test all features locally
2. Commit to GitHub
3. Deploy to platform (Vercel/Netlify)
4. Test in production
5. Monitor performance

## 📚 Learning Resources

### Files to Understand First
1. **index.html** - Understand the structure
2. **styles.css** - Learn the styling approach
3. **app.js** - Understand the logic

### Topics to Master
- Supabase integration
- Chart.js library
- Responsive CSS design
- JavaScript Promises/async-await
- DOM manipulation

### Code Examples in Project
- Fetching data from Supabase
- Creating charts with Chart.js
- Table filtering with JavaScript
- CSV export functionality
- Responsive grid layouts

---

**Project Created**: January 2026
**Version**: 1.0.0
**Status**: Production Ready ✅
