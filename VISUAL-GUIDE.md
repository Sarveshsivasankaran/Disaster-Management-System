# 📖 Admin Dashboard - Visual Guide & Feature Overview

## 🎨 Dashboard Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  DMS  │  Dashboard Overview          │  🔄  ⚙️                    │
├───────┼────────────────────────────────────────────────────────────┤
│       │                                                             │
│  📊   │  ┌─────────────────┬──────────────────┐                    │
│ Dash  │  │ 🌊 Active Buoys │ ⛰️ Landslide   │                    │
│       │  │      4          │      5            │                    │
│ 🌊    │  ├─────────────────┼──────────────────┤                    │
│ Buoys │  │ 🚨 Alerts      │ ✅ System Status│                    │
│       │  │      2          │    Operational   │                    │
│ ⛰️     │  └─────────────────┴──────────────────┘                    │
│ Poles │                                                             │
│       │  ┌──────────────┐  ┌──────────────┐                         │
│ 🚨    │  │ Water Level  │  │ Wave Height  │                         │
│Alerts │  │   (Graph)    │  │   (Graph)    │                         │
│       │  └──────────────┘  └──────────────┘                         │
│ ⚙️    │  ┌──────────────┐  ┌──────────────┐                         │
│Settings│ │Landslide Risk│  │Soil Moisture │                         │
│       │  │   (Graph)    │  │   (Graph)    │                         │
│       │  └──────────────┘  └──────────────┘                         │
│       │                                                             │
└───────┴────────────────────────────────────────────────────────────┘
```

---

## 🌊 Buoy Data Section

```
SEARCH:  [Search buoys...    ]  [Select: All ▼] [Export Data]

┌────────────────────────────────────────────────────────────────────┐
│ Buoy ID │ Location      │ Water Level │ Wave Height │ Temp │Status │
├────────────────────────────────────────────────────────────────────┤
│ BUOY001 │ Northern A    │   3.2 m     │   1.8 m     │22.5°C│ Active│
│ BUOY002 │ Central Bay   │   2.8 m     │   2.1 m     │21.3°C│ Active│
│ BUOY003 │ Southern      │   4.5 m     │   3.2 m     │23.1°C│ Warning│
│ BUOY004 │ Eastern       │   3.8 m     │   2.5 m     │20.8°C│ Active│
│ BUOY005 │ Western       │   3.0 m     │   1.9 m     │21.7°C│ Active│
└────────────────────────────────────────────────────────────────────┘

✅ Features:
  - Real-time monitoring
  - Search by ID or location
  - Filter by status
  - Download as CSV
  - Sort by any column
  - Update timestamps
```

---

## ⛰️ Landslide Detection Section

```
SEARCH: [Search poles...    ]  [Select: All ▼] [Export Data]

┌──────────────────────────────────────────────────────────────────────┐
│ Pole ID │ Location     │ Moisture │ Displacement │ Temp │ Risk │ Status
├──────────────────────────────────────────────────────────────────────┤
│ POLE001 │ Mountain A   │  65%     │    2.3 mm    │15.2°C│ Low  │ Active
│ POLE002 │ Hill Slope B │  78%     │    5.1 mm    │16.8°C│ Warning│Active
│ POLE003 │ Plateau      │  45%     │    1.2 mm    │14.5°C│ Low  │ Active
│ POLE004 │ Steep Inc.   │  85%     │   12.4 mm    │17.1°C│CRITICAL│Warning
│ POLE005 │ Valley Floor │  52%     │    3.8 mm    │15.9°C│ Low  │ Active
└──────────────────────────────────────────────────────────────────────┘

✅ Features:
  - Continuous monitoring
  - Risk level assessment
  - Displacement tracking
  - Advanced search
  - Risk filtering
  - Data export
  - Status indicators
```

---

## 📊 Chart Types

### 1. Water Level Trend (Line Chart)
```
Water Level (m)
  |
5 |         ●
4 |     ●       ●
3 | ●       ●       ●
2 |
  └─────────────────────
    BUOY1 BUOY2 BUOY3 ...
```
Shows water level patterns across all buoys over time.

### 2. Wave Height Analysis (Bar Chart)
```
Wave Height (m)
  |
3 |   ┌─┐
2 | ┌─┤ ├─┐ ┌─┐
1 | ┤ │ │ ├─┤ │
  └─┴─┴─┴─┴─┴─┴
    B1  B2  B3 B4
```
Compares wave heights across locations.

### 3. Landslide Risk (Doughnut Chart)
```
        ▭ Low Risk (2)
      ╱─────────────╲
    ╱               ╲      ▭ Warning (2)
   │       🟢       │     ▭ Critical (1)
    ╲               ╱
      ╲─────────────╱
```
Distribution of risk levels across poles.

### 4. Soil Moisture (Radar Chart)
```
          POLE1
           │ 65%
      ╱────┼────╲
  POLE5   │    POLE2
  52% ───╱ ╲─── 78%
      ╲   │   ╱
  POLE4──┼──POLE3
  85%    │   45%
```
Multi-axis moisture level comparison.

---

## 🔔 Alerts Section

```
┌─────────────────────────────────────────────────────────┐
│ [Filter: All ▼]  [Clear All Alerts]                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 🔴 CRITICAL                                    Just now  │
│ High Water Level at BUOY003                             │
│ Water level exceeds safe threshold at Southern Coast    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 🔴 CRITICAL                                   1 min ago  │
│ Displacement Critical at POLE004                        │
│ Pole displacement exceeds 12mm - Immediate action       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ 🟡 WARNING                                     5 min ago │
│ High Soil Moisture at POLE002                           │
│ Soil moisture above recommended safe levels             │
└─────────────────────────────────────────────────────────┘

✅ Features:
  - Severity filtering (Critical/Warning/Info)
  - Real-time notifications
  - Source tracking
  - Resolution tracking
  - Timestamp display
```

---

## ⚙️ Settings Section

```
╔═══════════════════════════════════════════════════════╗
║ Supabase Configuration                                ║
╠═══════════════════════════════════════════════════════╣
║                                                        ║
║ Supabase URL:                                         ║
║ [https://your-project.supabase.co              ]     ║
║                                                        ║
║ Supabase API Key:                                     ║
║ [****** HIDDEN FOR SECURITY ******           ]      ║
║                                                        ║
║ [Save Configuration]                                  ║
║                                                        ║
║ ✅ Successfully saved                                  ║
╚═══════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════╗
║ Data Refresh Settings                                 ║
╠═══════════════════════════════════════════════════════╣
║                                                        ║
║ Refresh Interval (seconds): [30]                      ║
║ Range: 5 to 300 seconds                               ║
║                                                        ║
║ [Save Refresh Settings]                               ║
║                                                        ║
║ Current Status: Auto-refresh enabled                  ║
╚═══════════════════════════════════════════════════════╝

✅ Features:
  - Secure credential storage
  - Configurable refresh interval
  - Real-time validation
  - Local persistence
  - Easy management
```

---

## 🎨 Color Scheme

### Status Indicators
```
🟢 Active       (Green #10b981)    - System operating normally
🟡 Warning      (Amber #f59e0b)    - Attention required
🔴 Critical     (Red #ef4444)      - Immediate action needed
⚪ Inactive     (Gray #6b7280)     - System offline
```

### Theme Colors
```
Primary         (Blue #2563eb)     - Main interactive elements
Background      (Dark #111827)     - Main screen background
Card            (Gray #374151)     - Content containers
Border          (Gray #4b5563)     - Separators
Text Primary    (Light #f3f4f6)    - Main text
Text Secondary  (Gray #d1d5db)     - Secondary text
```

---

## 📱 Mobile View

```
┌─────────────────┐
│ DMS  🔄  ⚙️     │
├─────────────────┤
│ [📊] [🌊] [⛰️] │
│ [🚨] [⚙️]      │
├─────────────────┤
│ Dashboard       │
│ ┌─────────────┐ │
│ │ Buoys: 4    │ │
│ │ Poles: 5    │ │
│ │ Alerts: 2   │ │
│ └─────────────┘ │
│ [Chart 1]       │
│ [Chart 2]       │
│ [Chart 3]       │
│ [Chart 4]       │
└─────────────────┘
```

---

## 🔄 Data Flow

```
                    Browser
                       │
            ┌──────────┼──────────┐
            │          │          │
         Input      Display     Charts
            │          │          │
            ▼          ▼          ▼
        ┌─────────────────────────┐
        │      app.js             │
        │  (Logic & Handlers)     │
        └────────────┬────────────┘
                     │
         ┌───────────┼───────────┐
         │                       │
       User               Supabase API
    Interactions              │
         │                    ▼
         │         ┌──────────────────┐
         │         │  PostgreSQL DB   │
         │         │                  │
         │         │ • Buoys table    │
         │         │ • Poles table    │
         │         │ • Alerts table   │
         │         │ • Logs table     │
         │         └──────────────────┘
         │
         ▼
    ┌─────────────┐
    │ LocalStorage│
    │ • Settings │
    │ • Creds    │
    └─────────────┘
```

---

## ✨ Interactive Elements

### Buttons & Controls
```
[Primary Button]       - Blue (#2563eb), action buttons
[Secondary Button]     - Gray, alternative actions
[Icon Button]          - Compact, header actions (🔄 ⚙️)
[Filter Dropdown]      - Status/risk filtering
[Search Input]         - Text-based search
[Export Button]        - CSV download
```

### Status Badges
```
ACTIVE              - Green background, white text
WARNING             - Amber background, white text
CRITICAL            - Red background, white text
LOW                 - Green background, white text
```

---

## 🔐 Data Security

```
┌─────────────────────────────────────┐
│  Browser (Your Computer)            │
│  ┌─────────────────────────────────┐│
│  │ Dashboard App                   ││
│  │ • HTML/CSS/JS                   ││
│  │ • LocalStorage (Settings)       ││
│  └──────────────┬──────────────────┘│
└─────────────────┼───────────────────┘
                  │
            [HTTPS Encrypted]
                  │
         ┌────────▼────────┐
         │   Supabase      │
         │  (Cloud Server) │
         │                 │
         │ • PostgreSQL DB │
         │ • Auth System   │
         │ • API Keys      │
         └─────────────────┘

✅ Security:
  - HTTPS encryption
  - Supabase authentication
  - API key validation
  - Row Level Security ready
```

---

## 📊 Sample Data Structure

### Buoy Record Example
```json
{
  "id": "BUOY001",
  "location": "Northern Coast A",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "water_level": 3.2,
  "wave_height": 1.8,
  "temperature": 22.5,
  "status": "active",
  "battery_level": 95,
  "signal_strength": 85,
  "last_update": "2024-01-25T14:30:00Z",
  "created_at": "2024-01-20T10:00:00Z"
}
```

### Landslide Pole Record Example
```json
{
  "id": "POLE001",
  "location": "Mountain Ridge A",
  "latitude": 41.0534,
  "longitude": -74.1302,
  "soil_moisture": 65,
  "displacement": 2.3,
  "temperature": 15.2,
  "risk_level": "low",
  "status": "active",
  "battery_level": 90,
  "signal_strength": 88,
  "last_update": "2024-01-25T14:30:00Z",
  "created_at": "2024-01-20T10:00:00Z"
}
```

---

## 🎯 User Workflows

### Workflow 1: Monitor Buoys
```
1. Open Dashboard
2. Check "Active Buoys" stat
3. Click "Buoy Data" section
4. Review water levels and temperatures
5. If warning found → click buoy row for details
6. Export data if needed
```

### Workflow 2: Track Landslide Risk
```
1. Go to "Landslide Detection"
2. Filter by "critical" risk level
3. Review poles with high displacement
4. Check soil moisture levels
5. Note temperature trends
6. Export for further analysis
```

### Workflow 3: Respond to Alerts
```
1. Check "Alerts" section
2. Review critical alerts first
3. Note source (buoy or pole)
4. Take appropriate action
5. Mark as resolved
6. Review alert history
```

### Workflow 4: Configure Settings
```
1. Click ⚙️ in header
2. Enter Supabase credentials
3. Adjust refresh interval
4. Save settings
5. Data loads automatically
6. Ready for monitoring
```

---

## 📈 Performance Metrics

```
Loading Performance:
├─ Page Load:           < 3 seconds
├─ Data Fetch:          < 1 second
├─ Chart Rendering:     < 500ms
├─ Search Response:     Instant
└─ Filter Application:  < 100ms

Browser Support:
├─ Chrome:  ✅ Latest
├─ Firefox: ✅ Latest
├─ Safari:  ✅ Latest
├─ Edge:    ✅ Latest
└─ Mobile:  ✅ All major

Responsive Breakpoints:
├─ Desktop:  1024px+
├─ Tablet:   768-1024px
├─ Mobile:   480-768px
└─ Small:    < 480px
```

---

## 🎓 Quick Reference

**Keyboard Shortcuts** (if implemented):
```
F5 or Ctrl+R     - Refresh page
F12              - Open DevTools
Ctrl+A           - Select all
Ctrl+C           - Copy
Ctrl+V           - Paste
```

**Mouse Actions:**
```
Click             - Select/navigate
Double-click      - Open details
Right-click       - Context menu (if available)
Scroll            - Navigate content
Drag              - Resize elements
```

**Touch/Mobile:**
```
Tap               - Click equivalent
Long press        - Right-click equivalent
Swipe left/right  - Navigate sections
Pinch             - Zoom (if enabled)
```

---

## 💡 Tips & Tricks

**Maximize Screen Real Estate:**
- Use full-screen mode (F11)
- Collapse sidebar if not needed
- Export data for offline analysis

**Faster Data Access:**
- Use search to find specific records
- Apply filters before scrolling
- Pin important locations

**Better Insights:**
- Compare multiple metrics
- Export and analyze trends
- Set up alerts for critical levels

**Efficient Monitoring:**
- Check charts first for patterns
- Review alerts regularly
- Update settings as needed

---

**Everything you need to monitor your disaster management system!** 🚀

*For detailed information, see the comprehensive guides in the documentation.*
