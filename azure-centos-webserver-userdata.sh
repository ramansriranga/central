#!/bin/bash

# Azure CentOS 8.x User Data Script for Web Server Installation and Configuration
# This script installs and configures Apache HTTP Server on CentOS 8.x

# Log all output for debugging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting user data script execution at $(date)"

# Update system packages
echo "Updating system packages..."
dnf update -y

# Install Apache HTTP Server and required packages
echo "Installing Apache HTTP Server and dependencies..."
dnf install -y httpd mod_ssl firewalld

# Install additional useful packages
echo "Installing additional packages..."
dnf install -y wget curl nano vim htop

# Start and enable firewalld
echo "Configuring firewall..."
systemctl start firewalld
systemctl enable firewalld

# Configure firewall rules for HTTP and HTTPS
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Start and enable Apache service
echo "Starting and enabling Apache service..."
systemctl start httpd
systemctl enable httpd

# Create a custom index.html page
echo "Creating custom web page..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Azure CentOS Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 2rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
        }
        .info {
            margin: 1rem 0;
            font-size: 1.1rem;
        }
        .status {
            background: rgba(46, 204, 113, 0.8);
            padding: 0.5rem 1rem;
            border-radius: 5px;
            display: inline-block;
            margin: 1rem 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Welcome to Azure CentOS Web Server</h1>
        <div class="status">✅ Server is Running Successfully</div>
        <div class="info">
            <p><strong>Operating System:</strong> CentOS 8.x</p>
            <p><strong>Web Server:</strong> Apache HTTP Server</p>
            <p><strong>Cloud Platform:</strong> Microsoft Azure</p>
            <p><strong>Server Time:</strong> <span id="datetime"></span></p>
        </div>
        <p>Your web server is now ready to serve content!</p>
    </div>
    
    <script>
        function updateDateTime() {
            const now = new Date();
            document.getElementById('datetime').textContent = now.toLocaleString();
        }
        updateDateTime();
        setInterval(updateDateTime, 1000);
    </script>
</body>
</html>
EOF

# Create a basic info page
echo "Creating server info page..."
cat > /var/www/html/info.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Information</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #007acc; padding-bottom: 10px; }
        .info-item { margin: 15px 0; padding: 10px; background: #f8f9fa; border-left: 4px solid #007acc; }
        .info-label { font-weight: bold; color: #555; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Server Information</h1>
        <div class="info-item">
            <span class="info-label">Hostname:</span> 
            <span id="hostname"></span>
        </div>
        <div class="info-item">
            <span class="info-label">Server Software:</span> Apache HTTP Server
        </div>
        <div class="info-item">
            <span class="info-label">Operating System:</span> CentOS 8.x
        </div>
        <div class="info-item">
            <span class="info-label">Cloud Provider:</span> Microsoft Azure
        </div>
        <div class="info-item">
            <span class="info-label">Current Time:</span> 
            <span id="current-time"></span>
        </div>
    </div>
    
    <script>
        // Set hostname (will be populated by server)
        document.getElementById('hostname').textContent = window.location.hostname;
        
        // Update current time
        function updateTime() {
            document.getElementById('current-time').textContent = new Date().toLocaleString();
        }
        updateTime();
        setInterval(updateTime, 1000);
    </script>
</body>
</html>
EOF

# Configure Apache with security best practices
echo "Configuring Apache security settings..."

# Create custom Apache configuration
cat > /etc/httpd/conf.d/security.conf << 'EOF'
# Security configurations for Apache

# Hide Apache version information
ServerTokens Prod
ServerSignature Off

# Prevent access to .htaccess files
<Files ".ht*">
    Require all denied
</Files>

# Disable directory browsing
Options -Indexes

# Prevent access to sensitive files
<FilesMatch "\.(htaccess|htpasswd|ini|log|sh|inc|bak)$">
    Require all denied
</FilesMatch>

# Add security headers
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"

# Set proper MIME types
<IfModule mod_mime.c>
    AddType application/javascript .js
    AddType text/css .css
</IfModule>
EOF

# Set proper permissions for web directory
echo "Setting proper file permissions..."
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html
find /var/www/html -type f -exec chmod 644 {} \;

# Configure log rotation for Apache logs
echo "Configuring log rotation..."
cat > /etc/logrotate.d/httpd << 'EOF'
/var/log/httpd/*log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 apache apache
    sharedscripts
    postrotate
        /bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true
    endscript
}
EOF

# Install and configure mod_evasive for DDoS protection
echo "Installing mod_evasive for DDoS protection..."
dnf install -y epel-release
dnf install -y mod_evasive

cat > /etc/httpd/conf.d/mod_evasive.conf << 'EOF'
<IfModule mod_evasive24.c>
    DOSHashTableSize    1024
    DOSPageCount        3
    DOSSiteCount        50
    DOSPageInterval     1
    DOSSiteInterval     1
    DOSBlockingPeriod   600
    DOSEmailNotify      admin@localhost
    DOSLogDir           /var/log/mod_evasive
</IfModule>
EOF

# Create mod_evasive log directory
mkdir -p /var/log/mod_evasive
chown apache:apache /var/log/mod_evasive

# Enable and start chronyd for time synchronization
echo "Configuring time synchronization..."
systemctl enable chronyd
systemctl start chronyd

# Configure automatic security updates
echo "Configuring automatic security updates..."
dnf install -y dnf-automatic
systemctl enable dnf-automatic.timer
systemctl start dnf-automatic.timer

# Create a maintenance script
echo "Creating maintenance script..."
cat > /usr/local/bin/webserver-maintenance.sh << 'EOF'
#!/bin/bash
# Web server maintenance script

echo "$(date): Starting web server maintenance"

# Update system packages
dnf update -y

# Check Apache configuration
httpd -t

# Restart Apache if configuration is valid
if [ $? -eq 0 ]; then
    systemctl restart httpd
    echo "$(date): Apache restarted successfully"
else
    echo "$(date): Apache configuration error detected"
fi

# Check disk usage
df -h

# Check memory usage
free -h

# Check Apache status
systemctl status httpd

echo "$(date): Web server maintenance completed"
EOF

chmod +x /usr/local/bin/webserver-maintenance.sh

# Add maintenance script to cron (weekly execution)
echo "0 2 * * 0 /usr/local/bin/webserver-maintenance.sh >> /var/log/webserver-maintenance.log 2>&1" | crontab -

# Restart Apache to apply all configurations
echo "Restarting Apache with new configurations..."
systemctl restart httpd

# Test Apache configuration
httpd -t
if [ $? -eq 0 ]; then
    echo "Apache configuration test passed"
else
    echo "Apache configuration test failed"
fi

# Display service status
echo "Checking service status..."
systemctl status httpd --no-pager
systemctl status firewalld --no-pager

# Create a script to display server information
cat > /usr/local/bin/server-info.sh << 'EOF'
#!/bin/bash
echo "=================================="
echo "Azure CentOS Web Server Status"
echo "=================================="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/redhat-release)"
echo "Uptime: $(uptime)"
echo "Apache Status: $(systemctl is-active httpd)"
echo "Firewall Status: $(systemctl is-active firewalld)"
echo "=================================="
echo "Network Information:"
ip addr show | grep -E "inet.*eth0"
echo "=================================="
echo "Disk Usage:"
df -h /
echo "=================================="
echo "Memory Usage:"
free -h
echo "=================================="
EOF

chmod +x /usr/local/bin/server-info.sh

# Run server info script
/usr/local/bin/server-info.sh

echo "User data script execution completed at $(date)"
echo "Web server installation and configuration finished successfully!"
echo "You can access your web server at: http://$(curl -s http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2017-08-01 -H Metadata:true)"
echo "Server info page available at: http://$(curl -s http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2017-08-01 -H Metadata:true)/info.html"