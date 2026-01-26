# Testing & Quality Assurance Guide

## 🧪 Testing Checklist

### Pre-Launch Testing

#### UI/UX Testing
- [ ] All sections load correctly
- [ ] Navigation works smoothly
- [ ] Sidebar items are clickable
- [ ] Responsive design on mobile/tablet
- [ ] No console errors (F12)
- [ ] All images/icons display
- [ ] Colors are consistent
- [ ] Fonts render correctly

#### Functionality Testing
- [ ] Dashboard loads with stats
- [ ] Charts render and display data
- [ ] Search functionality works
- [ ] Filter dropdown works
- [ ] Table sorting works
- [ ] Export to CSV works
- [ ] Refresh button works
- [ ] Settings save correctly

#### Data Testing
- [ ] Buoy data loads from Supabase
- [ ] Landslide pole data loads
- [ ] Water level values display correctly
- [ ] Wave height values display correctly
- [ ] Soil moisture values display correctly
- [ ] Risk levels show correctly
- [ ] Status badges appear properly
- [ ] Timestamps update correctly

#### Browser Testing
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile browsers

## 🔍 Manual Testing Guide

### Test 1: Initial Load
```
1. Open index.html in browser
2. Expected: Dashboard section visible with mock data
3. Check: Stats cards populated, charts display
4. Verify: No JavaScript errors in console
```

### Test 2: Supabase Configuration
```
1. Click settings (⚙️) button
2. Go to Settings section
3. Enter test Supabase URL and API Key
4. Click "Save Configuration"
5. Expected: Settings saved message
6. Verify: Data refreshes if tables exist
```

### Test 3: Navigation
```
1. Click each navigation item:
   - Dashboard
   - Buoy Data
   - Landslide Detection
   - Alerts
   - Settings
2. Expected: Each section loads without errors
3. Verify: Page title updates
4. Check: Back button functionality if needed
```

### Test 4: Search Functionality
```
1. Go to Buoy Data section
2. Type in search box: "BUOY001"
3. Expected: Table filters to show only BUOY001
4. Clear search, verify all rows return
5. Repeat for Landslide Detection section
```

### Test 5: Filter Functionality
```
1. Go to Buoy Data section
2. Select "Active" from status filter
3. Expected: Only active buoys display
4. Change to "Warning"
5. Expected: Only warning buoys display
6. Reset to "All"
7. Verify: All buoys display again
```

### Test 6: Data Export
```
1. Go to Buoy Data section
2. Click "Export Data" button
3. Expected: CSV file downloads
4. Open CSV file
5. Verify: All columns and data present
6. Repeat for Landslide Data section
```

### Test 7: Charts Display
```
1. Stay on Dashboard section
2. Verify 4 charts visible:
   - Water Level (line chart)
   - Wave Height (bar chart)
   - Landslide Risk (doughnut chart)
   - Soil Moisture (radar chart)
3. Check: Charts display data correctly
4. Verify: Legend appears for each chart
```

### Test 8: Auto-Refresh
```
1. Go to Settings section
2. Change refresh interval to 10 seconds
3. Click "Save Refresh Settings"
4. Expected: Success message
5. Modify data in Supabase (if connected)
6. Wait 10 seconds
7. Expected: Dashboard updates automatically
```

### Test 9: Mobile Responsiveness
```
1. Press F12 to open DevTools
2. Click device toolbar (mobile icon)
3. Select iPhone/Android preset
4. Test each section:
   - Sidebar collapses properly
   - Content is readable
   - Tables scroll horizontally if needed
   - Buttons are clickable
   - Charts scale appropriately
```

### Test 10: Error Handling
```
1. Disconnect internet temporarily
2. Expected: Graceful error handling
3. Reconnect internet
4. Try to refresh - should work
5. Test with invalid Supabase credentials
6. Expected: Error message displayed
```

## 🐛 Common Issues & Solutions

### Issue: "No data" appears in tables
**Cause**: Tables don't exist or are empty
**Solution**: 
```sql
-- Run database-setup.sql in Supabase
-- Or insert sample data:
INSERT INTO buoys (id, location, water_level, wave_height, temperature, status)
VALUES ('TEST001', 'Test Location', 3.0, 2.0, 20.0, 'active');
```

### Issue: CORS Error in console
**Cause**: Supabase CORS not configured
**Solution**:
1. Go to Supabase Settings → API
2. Add your domain to CORS
3. Refresh dashboard

### Issue: Charts not rendering
**Cause**: Chart.js library not loaded
**Solution**:
1. Check internet connection
2. Open DevTools → Network tab
3. Verify Chart.js CDN loads
4. Hard refresh browser (Ctrl+F5)

### Issue: Styling looks wrong
**Cause**: CSS file not loaded
**Solution**:
1. Check Network tab in DevTools
2. Verify styles.css loads (HTTP 200)
3. Check for CSS syntax errors
4. Clear browser cache

### Issue: Settings not saving
**Cause**: localStorage disabled
**Solution**:
1. Check browser privacy settings
2. Allow cookies/storage for site
3. Try different browser
4. Check browser console for errors

## 📊 Performance Testing

### Load Time Test
```javascript
// Run in browser console:
console.time('Dashboard Load');
// ... interact with dashboard ...
console.timeEnd('Dashboard Load');
```

### Memory Usage Test
```
1. Open DevTools → Memory tab
2. Take heap snapshot
3. Interact with dashboard
4. Take another snapshot
5. Compare memory usage
6. Check for memory leaks
```

### Database Query Performance
```sql
-- Analyze query performance:
EXPLAIN ANALYZE SELECT * FROM buoys;
EXPLAIN ANALYZE SELECT * FROM landslide_poles;
```

## 🔐 Security Testing

### Test 1: API Key Exposure
```javascript
// Open DevTools → Network tab
// Check requests to Supabase
// Verify: API key shouldn't appear in URLs
// Check localStorage: Should only contain URLs
```

### Test 2: Data Validation
```javascript
// Try entering malicious input in search:
// <script>alert('xss')</script>
// Expected: Properly escaped, no alert
```

### Test 3: CORS Testing
```
1. Test from different origin (if possible)
2. Expected: CORS error in console if not configured
3. After configuration: Should work
```

## ✅ Regression Testing Checklist

### After Code Changes
- [ ] Run all manual tests again
- [ ] Check console for new errors
- [ ] Verify charts still render
- [ ] Test search/filter still works
- [ ] Confirm export still functions
- [ ] Test responsive design
- [ ] Check browser compatibility

### Before Deployment
- [ ] All tests pass
- [ ] No console errors
- [ ] Performance acceptable
- [ ] Mobile responsive
- [ ] All features work
- [ ] Documentation updated
- [ ] Credentials configured

## 🚀 Automated Testing (Optional)

### Using Selenium (Python)
```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select

# Initialize driver
driver = webdriver.Chrome()
driver.get("http://localhost:8000/index.html")

# Test navigation
nav_items = driver.find_elements(By.CLASS_NAME, "nav-item")
for item in nav_items:
    item.click()
    assert driver.find_element(By.ID, "page-title").is_displayed()

# Test search
search_input = driver.find_element(By.ID, "buoy-search")
search_input.send_keys("BUOY001")
# Add assertions...

driver.quit()
```

### Using Jest (JavaScript)
```javascript
// Example test file: app.test.js
describe('DisasterManagementDashboard', () => {
  let dashboard;

  beforeEach(() => {
    dashboard = new DisasterManagementDashboard();
  });

  test('should initialize app', () => {
    expect(dashboard).toBeDefined();
  });

  test('should filter buoys by search', () => {
    // Test logic...
  });
});
```

## 📈 Performance Benchmarks

### Target Metrics
- Page Load Time: < 3 seconds
- Time to Interactive: < 4 seconds
- First Contentful Paint: < 1.5 seconds
- Largest Contentful Paint: < 2.5 seconds

### Optimization Tips
1. Minify CSS/JS in production
2. Use CDN for external libraries
3. Compress images
4. Enable gzip compression
5. Cache static assets
6. Lazy load charts on demand

## 📝 Test Report Template

```
TEST REPORT - Disaster Management Dashboard
Date: [DATE]
Tester: [NAME]
Browser: [BROWSER] v[VERSION]
OS: [OS] [VERSION]

RESULTS:
┌─────────────────────────────────┬────────┐
│ Test Case                       │ Status │
├─────────────────────────────────┼────────┤
│ UI/UX Rendering                 │   ✅   │
│ Navigation                      │   ✅   │
│ Search Functionality            │   ✅   │
│ Data Export                     │   ✅   │
│ Chart Rendering                 │   ✅   │
│ Responsive Design               │   ✅   │
│ Error Handling                  │   ✅   │
│ Performance                     │   ✅   │
│ Security                        │   ✅   │
└─────────────────────────────────┴────────┘

ISSUES FOUND:
1. [Description] - Severity: [Low/Medium/High]
   Solution: [Proposed fix]

NOTES:
[Any additional observations]

APPROVAL:
✅ Ready for Production
⚠️  Needs Fixes
❌ Not Approved

Signed: ___________________
```

## 🔄 Continuous Integration Setup

### GitHub Actions Workflow
```yaml
name: Test Dashboard

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Tests
        run: npm test
      - name: Check Syntax
        run: npm run lint
```

## 📚 Resources

### Testing Tools
- **Browser DevTools**: Chrome/Firefox/Safari
- **Lighthouse**: Performance auditing
- **WAVE**: Accessibility testing
- **Selenium**: Automated testing
- **Jest**: JavaScript unit testing

### Best Practices
- Test in multiple browsers
- Test on multiple devices
- Test with slow network
- Test with disabled JavaScript
- Test keyboard navigation
- Test with screen readers

---

**Testing is crucial for quality assurance!**
Follow this guide to ensure your dashboard is robust and reliable.
