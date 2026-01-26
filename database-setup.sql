-- ============================================================================
-- DISASTER MANAGEMENT SYSTEM - DATABASE SETUP SCRIPT
-- ============================================================================
-- Run this SQL in your Supabase SQL Editor to set up the complete database
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE TABLES
-- ============================================================================

-- Buoys Table
CREATE TABLE IF NOT EXISTS buoys (
  id TEXT PRIMARY KEY,
  location VARCHAR(255) NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  water_level DECIMAL(10, 2),
  wave_height DECIMAL(10, 2),
  temperature DECIMAL(5, 2),
  status VARCHAR(50) DEFAULT 'active',
  battery_level INT,
  signal_strength INT,
  last_update TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Landslide Detection Poles Table
CREATE TABLE IF NOT EXISTS landslide_poles (
  id TEXT PRIMARY KEY,
  location VARCHAR(255) NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  soil_moisture DECIMAL(5, 2),
  displacement DECIMAL(10, 2),
  temperature DECIMAL(5, 2),
  risk_level VARCHAR(50) DEFAULT 'low',
  status VARCHAR(50) DEFAULT 'active',
  battery_level INT,
  signal_strength INT,
  last_update TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Alerts Table
CREATE TABLE IF NOT EXISTS alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  message TEXT,
  severity VARCHAR(50),
  source_type VARCHAR(50),
  source_id TEXT,
  is_resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  resolved_at TIMESTAMP
);

-- System Logs Table
CREATE TABLE IF NOT EXISTS system_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100),
  event_data JSONB,
  user_id TEXT,
  ip_address INET,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- STEP 2: CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_buoy_status ON buoys(status);
CREATE INDEX IF NOT EXISTS idx_buoy_location ON buoys(location);
CREATE INDEX IF NOT EXISTS idx_buoy_last_update ON buoys(last_update DESC);
CREATE INDEX IF NOT EXISTS idx_buoy_water_level ON buoys(water_level);

CREATE INDEX IF NOT EXISTS idx_pole_status ON landslide_poles(status);
CREATE INDEX IF NOT EXISTS idx_pole_location ON landslide_poles(location);
CREATE INDEX IF NOT EXISTS idx_pole_last_update ON landslide_poles(last_update DESC);
CREATE INDEX IF NOT EXISTS idx_pole_risk ON landslide_poles(risk_level);

CREATE INDEX IF NOT EXISTS idx_alerts_severity ON alerts(severity);
CREATE INDEX IF NOT EXISTS idx_alerts_source ON alerts(source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_alerts_resolved ON alerts(is_resolved);

-- ============================================================================
-- STEP 3: INSERT SAMPLE DATA
-- ============================================================================

-- Insert Sample Buoy Data
INSERT INTO buoys (id, location, latitude, longitude, water_level, wave_height, temperature, status, battery_level, signal_strength)
VALUES 
  ('BUOY001', 'Northern Coast A', 40.7128, -74.0060, 3.2, 1.8, 22.5, 'active', 95, 85),
  ('BUOY002', 'Central Bay', 40.6892, -74.0445, 2.8, 2.1, 21.3, 'active', 88, 78),
  ('BUOY003', 'Southern Coast', 40.5731, -73.9712, 4.5, 3.2, 23.1, 'warning', 60, 65),
  ('BUOY004', 'Eastern Waters', 40.7614, -73.9776, 3.8, 2.5, 20.8, 'active', 92, 88),
  ('BUOY005', 'Western Harbor', 40.6643, -74.1200, 3.0, 1.9, 21.7, 'active', 85, 82)
ON CONFLICT (id) DO NOTHING;

-- Insert Sample Landslide Pole Data
INSERT INTO landslide_poles (id, location, latitude, longitude, soil_moisture, displacement, temperature, risk_level, status, battery_level, signal_strength)
VALUES
  ('POLE001', 'Mountain Ridge A', 41.0534, -74.1302, 65, 2.3, 15.2, 'low', 'active', 90, 88),
  ('POLE002', 'Hill Slope B', 41.0595, -74.1307, 78, 5.1, 16.8, 'warning', 'active', 75, 72),
  ('POLE003', 'Plateau Region', 41.0603, -74.1251, 45, 1.2, 14.5, 'low', 'active', 88, 85),
  ('POLE004', 'Steep Incline C', 41.0511, -74.1273, 85, 12.4, 17.1, 'critical', 'warning', 45, 50),
  ('POLE005', 'Valley Floor', 41.0480, -74.1350, 52, 3.8, 15.9, 'low', 'active', 92, 90)
ON CONFLICT (id) DO NOTHING;

-- Insert Sample Alerts
INSERT INTO alerts (title, message, severity, source_type, source_id, is_resolved)
VALUES
  ('High Water Level', 'BUOY003 water level exceeds threshold', 'warning', 'buoy', 'BUOY003', FALSE),
  ('Critical Displacement', 'POLE004 displacement critical - immediate attention needed', 'critical', 'pole', 'POLE004', FALSE),
  ('High Soil Moisture', 'POLE002 soil moisture above safe levels', 'warning', 'pole', 'POLE002', TRUE)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- STEP 4: CREATE VIEWS FOR DASHBOARD
-- ============================================================================

-- View for Buoy Summary
CREATE OR REPLACE VIEW v_buoy_summary AS
SELECT 
  COUNT(*) as total_buoys,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_buoys,
  COUNT(CASE WHEN status = 'warning' THEN 1 END) as warning_buoys,
  COUNT(CASE WHEN status = 'critical' THEN 1 END) as critical_buoys,
  AVG(water_level) as avg_water_level,
  AVG(wave_height) as avg_wave_height,
  AVG(temperature) as avg_temperature
FROM buoys;

-- View for Landslide Summary
CREATE OR REPLACE VIEW v_landslide_summary AS
SELECT 
  COUNT(*) as total_poles,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_poles,
  COUNT(CASE WHEN status = 'warning' THEN 1 END) as warning_poles,
  COUNT(CASE WHEN risk_level = 'low' THEN 1 END) as low_risk_poles,
  COUNT(CASE WHEN risk_level = 'warning' THEN 1 END) as warning_risk_poles,
  COUNT(CASE WHEN risk_level = 'critical' THEN 1 END) as critical_poles,
  AVG(soil_moisture) as avg_soil_moisture,
  AVG(displacement) as avg_displacement
FROM landslide_poles;

-- View for Recent Alerts
CREATE OR REPLACE VIEW v_recent_alerts AS
SELECT 
  id,
  title,
  message,
  severity,
  source_type,
  source_id,
  is_resolved,
  created_at,
  CASE 
    WHEN severity = 'critical' THEN 1
    WHEN severity = 'warning' THEN 2
    ELSE 3
  END as severity_order
FROM alerts
ORDER BY created_at DESC, severity_order ASC
LIMIT 50;

-- ============================================================================
-- STEP 5: CREATE FUNCTIONS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Function to update last_update timestamp
CREATE OR REPLACE FUNCTION update_buoy_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_update = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for buoys table
DROP TRIGGER IF EXISTS trigger_update_buoy_timestamp ON buoys;
CREATE TRIGGER trigger_update_buoy_timestamp
  BEFORE UPDATE ON buoys
  FOR EACH ROW
  EXECUTE FUNCTION update_buoy_timestamp();

-- Function for landslide poles
CREATE OR REPLACE FUNCTION update_pole_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_update = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for poles table
DROP TRIGGER IF EXISTS trigger_update_pole_timestamp ON landslide_poles;
CREATE TRIGGER trigger_update_pole_timestamp
  BEFORE UPDATE ON landslide_poles
  FOR EACH ROW
  EXECUTE FUNCTION update_pole_timestamp();

-- ============================================================================
-- STEP 6: GRANT PERMISSIONS (Adjust as needed)
-- ============================================================================

-- Allow public read access (modify as needed for security)
GRANT SELECT ON buoys TO anon;
GRANT SELECT ON landslide_poles TO anon;
GRANT SELECT ON alerts TO anon;
GRANT SELECT ON v_buoy_summary TO anon;
GRANT SELECT ON v_landslide_summary TO anon;
GRANT SELECT ON v_recent_alerts TO anon;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify setup:

-- SELECT * FROM buoys;
-- SELECT * FROM landslide_poles;
-- SELECT * FROM alerts;
-- SELECT * FROM v_buoy_summary;
-- SELECT * FROM v_landslide_summary;
-- SELECT * FROM v_recent_alerts;

-- ============================================================================
-- MAINTENANCE QUERIES
-- ============================================================================

-- Clean up old data (optional - run as needed)
-- DELETE FROM alerts WHERE created_at < NOW() - INTERVAL '30 days' AND is_resolved = TRUE;
-- DELETE FROM system_logs WHERE created_at < NOW() - INTERVAL '90 days';

-- Update sample data (for testing)
-- UPDATE buoys SET water_level = water_level + RANDOM() - 0.5, last_update = NOW() WHERE id = 'BUOY001';

-- ============================================================================
-- DATABASE SETUP COMPLETE
-- ============================================================================
-- Your database is now ready for use!
-- You can now:
-- 1. Configure Supabase credentials in the dashboard
-- 2. Start monitoring buoy and landslide data
-- 3. View real-time dashboards and alerts
