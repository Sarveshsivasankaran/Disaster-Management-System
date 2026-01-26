# Quick Start Guide - Disaster Management System Dashboard

## 5-Minute Setup

### Step 1: Get Supabase Credentials (2 minutes)
1. Go to [supabase.com](https://supabase.com) and sign in
2. Create a new project or select existing one
3. Go to Settings → API
4. Copy your **Project URL** and **anon public key**

### Step 2: Create Database Tables (2 minutes)

Go to SQL Editor in Supabase and run:

```sql
-- Create Buoys table
CREATE TABLE buoys (
  id TEXT PRIMARY KEY,
  location VARCHAR(255),
  water_level DECIMAL(10, 2),
  wave_height DECIMAL(10, 2),
  temperature DECIMAL(5, 2),
  status VARCHAR(50),
  last_update TIMESTAMP DEFAULT NOW()
);

-- Create Landslide Poles table
CREATE TABLE landslide_poles (
  id TEXT PRIMARY KEY,
  location VARCHAR(255),
  soil_moisture DECIMAL(5, 2),
  displacement DECIMAL(10, 2),
  temperature DECIMAL(5, 2),
  risk_level VARCHAR(50),
  status VARCHAR(50),
  last_update TIMESTAMP DEFAULT NOW()
);
```

### Step 3: Add Sample Data (1 minute)

```sql
-- Insert Buoy Data
INSERT INTO buoys (id, location, water_level, wave_height, temperature, status) VALUES
('BUOY001', 'Northern Coast A', 3.2, 1.8, 22.5, 'active'),
('BUOY002', 'Central Bay', 2.8, 2.1, 21.3, 'active'),
('BUOY003', 'Southern Coast', 4.5, 3.2, 23.1, 'warning'),
('BUOY004', 'Eastern Waters', 3.8, 2.5, 20.8, 'active');

-- Insert Landslide Pole Data
INSERT INTO landslide_poles (id, location, soil_moisture, displacement, temperature, risk_level, status) VALUES
('POLE001', 'Mountain Ridge A', 65, 2.3, 15.2, 'low', 'active'),
('POLE002', 'Hill Slope B', 78, 5.1, 16.8, 'warning', 'active'),
('POLE003', 'Plateau Region', 45, 1.2, 14.5, 'low', 'active'),
('POLE004', 'Steep Incline C', 85, 12.4, 17.1, 'critical', 'warning');
```

### Step 4: Open Dashboard
1. Open `index.html` in your browser
2. Click ⚙️ (settings) in the top right
3. Go to Settings section
4. Paste your Supabase URL and API Key
5. Click "Save Configuration"
6. Navigate to Dashboard to see your data!

## Dashboard Features Explained

### 📊 Dashboard Tab
- **Stats Cards**: Shows total active buoys, poles, alerts
- **Line Chart**: Water level trends over time
- **Bar Chart**: Wave heights comparison
- **Doughnut Chart**: Risk level distribution
- **Radar Chart**: Soil moisture levels

### 🌊 Buoy Data Tab
- View all buoy measurements
- Search by buoy ID or location
- Filter by status (Active, Warning, Critical)
- Export data as CSV
- Sort by clicking column headers

### ⛰️ Landslide Detection Tab
- Monitor all landslide detection poles
- View soil moisture and displacement
- Risk level indicators
- Pole status (Active/Warning)
- Export for analysis

### 🚨 Alerts Tab
- System alerts and notifications
- Filter by severity level
- Clear alerts when resolved

### ⚙️ Settings Tab
- Configure Supabase connection
- Set auto-refresh interval (5-300 seconds)
- Save settings to browser

## Common Tasks

### Update Buoy Data
```sql
UPDATE buoys 
SET water_level = 3.5, last_update = NOW()
WHERE id = 'BUOY001';
```

### Update Landslide Pole
```sql
UPDATE landslide_poles 
SET soil_moisture = 72, displacement = 3.2, last_update = NOW()
WHERE id = 'POLE001';
```

### Add New Buoy
```sql
INSERT INTO buoys (id, location, water_level, wave_height, temperature, status)
VALUES ('BUOY005', 'New Location', 3.0, 2.0, 21.0, 'active');
```

### View Data in Supabase
1. Go to Supabase SQL Editor
2. Run: `SELECT * FROM buoys;`
3. Or use the Table Editor to view/edit data directly

## Customization Tips

### Change Refresh Interval
- Go to Settings
- Adjust "Refresh Interval (seconds)"
- Default is 30 seconds (minimum 5, maximum 300)

### Add New Status Types
Edit `app.js` and add to CSS classes:
```css
.status-inactive { background-color: rgba(107, 114, 128, 0.2); color: #6b7280; }
```

### Change Dashboard Theme Colors
Edit `styles.css` `:root` variables:
```css
:root {
    --primary-color: #your-color;
    --danger-color: #your-color;
    /* etc */
}
```

## Troubleshooting

### Dashboard shows "No data"
1. Check Supabase credentials are correct
2. Verify tables exist in Supabase
3. Insert sample data (see above)
4. Click refresh button (🔄)

### Charts not showing
- Browser console (F12) should show any errors
- Check that data was inserted correctly
- Try clearing browser cache and reload

### Slow performance
- Reduce number of records
- Increase refresh interval in Settings
- Use modern browser (Chrome/Firefox)

### Export not working
- Check browser download settings
- Try different browser
- Check file size isn't too large

## File Descriptions

| File | Purpose |
|------|---------|
| `index.html` | Dashboard UI structure |
| `styles.css` | Styling and layout |
| `app.js` | Logic and Supabase integration |
| `README.md` | Full documentation |
| `QUICKSTART.md` | This file |

## Next Steps

1. ✅ Setup dashboard
2. ✅ Add your data to Supabase
3. Configure custom settings
4. Set up automated data collection
5. Share with team members

## Support

For issues:
1. Check browser console (F12)
2. Verify Supabase credentials
3. Check database tables and data
4. Try clearing browser cache
5. Restart the dashboard

## Production Checklist

Before deploying to production:
- [ ] Set up Row Level Security (RLS) in Supabase
- [ ] Use environment variables for credentials
- [ ] Enable HTTPS
- [ ] Set up user authentication
- [ ] Configure backup strategy
- [ ] Set up monitoring/alerts
- [ ] Document API endpoints
- [ ] Test data export functionality

---

**Ready to go!** 🚀 Your Disaster Management Dashboard is now running.
