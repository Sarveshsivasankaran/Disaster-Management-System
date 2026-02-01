-- Add date and time columns to sos_alerts table
ALTER TABLE sos_alerts 
ADD COLUMN IF NOT EXISTS date TEXT,
ADD COLUMN IF NOT EXISTS time TEXT;

-- Verify the columns were added
-- SELECT * FROM sos_alerts LIMIT 1;
