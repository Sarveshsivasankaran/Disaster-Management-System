# Deployment Guide

## Local Development

### Using Python HTTP Server
```bash
cd "h:\Program files\Disaster-Management-System"
python -m http.server 8000
# Open browser to http://localhost:8000
```

### Using Node.js
```bash
npm install -g http-server
cd "h:\Program files\Disaster-Management-System"
http-server
# Open browser to http://localhost:8080
```

### Using Live Server (VS Code)
1. Install Live Server extension
2. Right-click `index.html`
3. Select "Open with Live Server"

## Deploying to Production

### Option 1: GitHub Pages (Free)

1. **Create GitHub Repository**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/yourusername/disaster-dashboard.git
   git push -u origin main
   ```

2. **Enable GitHub Pages**
   - Go to repository Settings
   - Select "Pages"
   - Set source to "main" branch
   - Your site will be available at `https://yourusername.github.io/disaster-dashboard`

3. **Update Supabase Credentials**
   - Add allowed origins in Supabase dashboard
   - Security → CORS → Add your GitHub Pages URL

### Option 2: Vercel (Free, Recommended)

1. **Push to GitHub** (if not already done)

2. **Deploy to Vercel**
   - Go to [vercel.com](https://vercel.com)
   - Click "New Project"
   - Import your GitHub repository
   - Click "Deploy"

3. **Configure Environment**
   - Add Supabase URL to allowed origins
   - Custom domain optional

### Option 3: Netlify (Free)

1. **Deploy via Git**
   - Go to [netlify.com](https://netlify.com)
   - Click "New site from Git"
   - Connect GitHub repository
   - Deploy automatically

2. **Configure Settings**
   - Update Supabase CORS
   - Add custom domain if desired

### Option 4: Self-Hosted (VPS)

1. **Setup Server**
   ```bash
   # Install web server (Nginx)
   sudo apt update
   sudo apt install nginx
   
   # Enable and start service
   sudo systemctl start nginx
   sudo systemctl enable nginx
   ```

2. **Deploy Files**
   ```bash
   # Copy files to web root
   sudo cp -r /path/to/files/* /var/www/html/
   
   # Set permissions
   sudo chown -R www-data:www-data /var/www/html
   sudo chmod -R 755 /var/www/html
   ```

3. **Setup SSL (HTTPS)**
   ```bash
   # Install Certbot
   sudo apt install certbot python3-certbot-nginx
   
   # Get certificate
   sudo certbot certonly --nginx -d yourdomain.com
   
   # Auto-renewal
   sudo systemctl enable certbot.timer
   ```

4. **Configure CORS in Supabase**
   - Add your domain to allowed origins

## Security Best Practices

### 1. Environment Variables
Create `.env` file (never commit to git):
```
VITE_SUPABASE_URL=your_url
VITE_SUPABASE_KEY=your_key
```

### 2. Row Level Security (RLS)
Enable in Supabase:
```sql
ALTER TABLE buoys ENABLE ROW LEVEL SECURITY;
ALTER TABLE landslide_poles ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users
CREATE POLICY "Authenticated users can read" ON buoys
  FOR SELECT USING (auth.role() = 'authenticated');
```

### 3. API Key Rotation
- Regularly rotate Supabase API keys
- Use service role keys for backend operations only
- Never expose anon keys in frontend (use restricted permissions)

### 4. HTTPS/SSL
- Always use HTTPS in production
- Use valid SSL certificates
- Enforce HTTPS redirect

### 5. CORS Configuration
Supabase → Settings → API → CORS:
```
https://yourdomain.com
https://www.yourdomain.com
```

## Monitoring & Maintenance

### Uptime Monitoring
```bash
# Monitor with Ping service
# Go to https://updown.io
# Add your domain
# Get alerts if site goes down
```

### Performance Monitoring
- Use Google PageSpeed Insights
- Monitor Lighthouse scores
- Track Core Web Vitals

### Database Backups
- Enable automatic backups in Supabase
- Backup: Settings → Backups
- Retention: 7 days (default)

### Logs & Debugging
- Browser DevTools (F12)
- Supabase SQL Editor for queries
- Check browser console for errors

## Scaling Considerations

### Database Optimization
```sql
-- Add indexes for faster queries
CREATE INDEX idx_buoy_status ON buoys(status);
CREATE INDEX idx_buoy_location ON buoys(location);
CREATE INDEX idx_pole_risk ON landslide_poles(risk_level);
```

### Caching Strategy
- Browser cache: Settings control refresh intervals
- Supabase replication: For read-heavy workloads
- CDN: For static assets

### Load Testing
```bash
# Using Apache Bench
ab -n 100 -c 10 https://yourdomain.com/

# Using curl
for i in {1..50}; do curl https://yourdomain.com & done
```

## Troubleshooting Deployment

### CORS Errors
```
Access to XMLHttpRequest has been blocked by CORS policy
```
**Solution**: Add your domain to Supabase CORS settings

### 404 Errors
**Solution**: Ensure all files are uploaded (index.html, styles.css, app.js)

### Blank Page
- Check browser console (F12)
- Verify Supabase credentials
- Check network requests
- Clear browser cache

### Slow Loading
- Optimize image sizes
- Enable gzip compression
- Use CDN for static files
- Reduce initial payload

## CI/CD Pipeline (GitHub Actions)

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./
```

## Rollback Procedure

### If Something Goes Wrong
1. Keep backup of previous version
2. Git commands:
   ```bash
   git log --oneline
   git revert <commit-hash>
   git push
   ```
3. Redeploy through platform
4. Clear CDN cache if applicable

## Checklist Before Going Live

- [ ] Supabase credentials configured
- [ ] CORS settings updated
- [ ] SSL/HTTPS enabled
- [ ] Database tables created
- [ ] Sample data inserted
- [ ] All pages tested
- [ ] Charts displaying correctly
- [ ] Export functionality working
- [ ] Search/filter working
- [ ] Refresh interval set
- [ ] Mobile responsive verified
- [ ] Backup strategy in place
- [ ] Monitoring enabled
- [ ] Security review completed
- [ ] Documentation updated

## Support & Help

### Resources
- Supabase Docs: https://supabase.com/docs
- Chart.js Docs: https://www.chartjs.org/docs/latest/
- GitHub Pages: https://pages.github.com/
- Vercel Docs: https://vercel.com/docs
- Netlify Docs: https://docs.netlify.com/

### Common Issues
- Issue: CORS errors → Solution: Update CORS in Supabase
- Issue: Data not loading → Solution: Check credentials
- Issue: Slow performance → Solution: Optimize queries
- Issue: 404 on refresh → Solution: Configure routing

---

**Happy Deploying!** 🚀
