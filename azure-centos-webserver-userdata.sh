#!/bin/bash

# Azure CentOS 8.x Web Server Setup Script
# This script installs and configures Apache HTTP Server on CentOS 8.x
# For use as Azure VM user data / custom script extension

# Log all output to a file for debugging
exec > /var/log/webserver-setup.log 2>&1

echo "Starting web server setup on CentOS 8.x - $(date)"

# Update system packages
echo "Updating system packages..."
dnf update -y

# Install Apache HTTP Server
echo "Installing Apache HTTP Server..."
dnf install -y httpd

# Install additional useful packages
echo "Installing additional packages..."
dnf install -y wget curl unzip firewalld

# Enable and start Apache service
echo "Enabling and starting Apache service..."
systemctl enable httpd
systemctl start httpd

# Configure firewall to allow HTTP and HTTPS traffic
echo "Configuring firewall..."
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Create a simple index.html page
echo "Creating default web page..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to CentOS Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .content {
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .status {
            background-color: #27ae60;
            color: white;
            padding: 10px;
            border-radius: 3px;
            margin: 10px 0;
        }
        .info {
            background-color: #3498db;
            color: white;
            padding: 10px;
            border-radius: 3px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 CentOS Web Server</h1>
        <p>Successfully deployed on Azure Virtual Machine</p>
    </div>
    
    <div class="content">
        <div class="status">
            ✅ Apache HTTP Server is running successfully!
        </div>
        
        <div class="info">
            <strong>Server Information:</strong><br>
            Operating System: CentOS 8.x<br>
            Web Server: Apache HTTP Server<br>
            Platform: Microsoft Azure<br>
            Setup Date: $(date)<br>
        </div>
        
        <h2>Next Steps</h2>
        <ul>
            <li>Upload your website files to <code>/var/www/html/</code></li>
            <li>Configure virtual hosts in <code>/etc/httpd/conf.d/</code></li>
            <li>Install SSL certificates for HTTPS</li>
            <li>Configure PHP, Python, or other application runtimes as needed</li>
        </ul>
        
        <h2>Useful Commands</h2>
        <ul>
            <li><code>sudo systemctl status httpd</code> - Check Apache status</li>
            <li><code>sudo systemctl restart httpd</code> - Restart Apache</li>
            <li><code>sudo journalctl -u httpd</code> - View Apache logs</li>
            <li><code>sudo firewall-cmd --list-all</code> - Check firewall rules</li>
        </ul>
        
        <h2>Important Directories</h2>
        <ul>
            <li><strong>Web Root:</strong> /var/www/html/</li>
            <li><strong>Configuration:</strong> /etc/httpd/conf/httpd.conf</li>
            <li><strong>Virtual Hosts:</strong> /etc/httpd/conf.d/</li>
            <li><strong>Logs:</strong> /var/log/httpd/</li>
        </ul>
    </div>
</body>
</html>
EOF

# Set proper permissions for web files
echo "Setting file permissions..."
chown -R apache:apache /var/www/html/
chmod -R 755 /var/www/html/

# Create a basic Apache virtual host configuration
echo "Creating virtual host configuration..."
cat > /etc/httpd/conf.d/default.conf << 'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html
    ErrorLog /var/log/httpd/error.log
    CustomLog /var/log/httpd/access.log combined
    
    <Directory "/var/www/html">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Configure Apache for better security and performance
echo "Configuring Apache security settings..."
cat >> /etc/httpd/conf.d/security.conf << 'EOF'
# Security configurations
ServerTokens Prod
ServerSignature Off

# Hide Apache version
Header always unset Server
Header unset X-Powered-By

# Prevent access to .htaccess files
<Files ".ht*">
    Require all denied
</Files>

# Disable server-status and server-info
<Location "/server-status">
    Require all denied
</Location>
<Location "/server-info">
    Require all denied
</Location>
EOF

# Enable mod_rewrite and mod_headers
echo "Enabling Apache modules..."
echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/httpd/conf.modules.d/00-base.conf
echo "LoadModule headers_module modules/mod_headers.so" >> /etc/httpd/conf.modules.d/00-base.conf

# Configure log rotation for Apache logs
echo "Configuring log rotation..."
cat > /etc/logrotate.d/httpd << 'EOF'
/var/log/httpd/*log {
    daily
    rotate 52
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        /bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true
    endscript
}
EOF

# Install and configure fail2ban for additional security (optional)
echo "Installing fail2ban for security..."
dnf install -y epel-release
dnf install -y fail2ban

# Configure fail2ban for Apache
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[apache-auth]
enabled = true
port = http,https
logpath = /var/log/httpd/error.log

[apache-badbots]
enabled = true
port = http,https
logpath = /var/log/httpd/access.log
maxretry = 2

[apache-noscript]
enabled = true
port = http,https
logpath = /var/log/httpd/access.log
maxretry = 6
EOF

# Enable and start fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Create a script for easy SSL certificate installation
echo "Creating SSL setup helper script..."
cat > /root/setup-ssl.sh << 'EOF'
#!/bin/bash
# SSL Certificate Setup Helper
# Run this script to install Let's Encrypt SSL certificates

echo "Installing Certbot for Let's Encrypt SSL..."
dnf install -y certbot python3-certbot-apache

echo "To obtain an SSL certificate, run:"
echo "certbot --apache -d your-domain.com"
echo ""
echo "To setup automatic renewal, add this to crontab:"
echo "0 12 * * * /usr/bin/certbot renew --quiet"
EOF

chmod +x /root/setup-ssl.sh

# Restart Apache to apply all configurations
echo "Restarting Apache with new configuration..."
systemctl restart httpd

# Verify Apache is running
if systemctl is-active --quiet httpd; then
    echo "✅ Apache HTTP Server is running successfully!"
else
    echo "❌ Failed to start Apache HTTP Server"
    systemctl status httpd
fi

# Display server status
echo "=== Server Setup Complete ==="
echo "Web Server: Apache HTTP Server"
echo "Status: $(systemctl is-active httpd)"
echo "OS: $(cat /etc/centos-release)"
echo "Public IP: $(curl -s ifconfig.me)"
echo "Local IP: $(hostname -I | awk '{print $1}')"
echo "Setup completed at: $(date)"
echo "=========================="

# Create a status check script
cat > /root/check-webserver.sh << 'EOF'
#!/bin/bash
echo "=== Web Server Status Check ==="
echo "Apache Status: $(systemctl is-active httpd)"
echo "Firewall Status: $(systemctl is-active firewalld)"
echo "Fail2ban Status: $(systemctl is-active fail2ban)"
echo "Open Ports: $(ss -tuln | grep -E ':80|:443')"
echo "Recent Apache Access:"
tail -5 /var/log/httpd/access.log
echo "Recent Apache Errors:"
tail -5 /var/log/httpd/error.log
echo "=============================="
EOF

chmod +x /root/check-webserver.sh

echo "Web server setup completed successfully!"
echo "Log file: /var/log/webserver-setup.log"
echo "Status check script: /root/check-webserver.sh"
echo "SSL setup script: /root/setup-ssl.sh"