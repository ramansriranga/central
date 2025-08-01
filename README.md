# Azure CentOS 8.x Web Server User Data Script

This repository contains a comprehensive user data script for automatically installing and configuring an Apache web server on Azure Virtual Machines running CentOS 8.x.

## Features

### 🚀 Automated Installation
- **Apache HTTP Server** with mod_ssl for HTTPS support
- **Firewall configuration** (firewalld) with HTTP/HTTPS rules
- **Security hardening** with best practices
- **DDoS protection** using mod_evasive
- **Automatic security updates** configuration

### 🔒 Security Features
- Server signature and version hiding
- Security headers (XSS protection, content type options, etc.)
- File access restrictions for sensitive files
- Proper file permissions and ownership
- mod_evasive for basic DDoS protection

### 🎨 Web Content
- **Beautiful landing page** with modern CSS and gradients
- **Server information page** with real-time updates
- **Responsive design** that works on all devices

### 🛠️ Maintenance & Monitoring
- **Automatic log rotation** for Apache logs
- **Weekly maintenance script** with cron job
- **Server information script** for quick status checks
- **Time synchronization** with chronyd

## Usage

### 1. Azure VM Creation via Azure Portal

1. **Create a new Virtual Machine** in Azure Portal
2. **Select CentOS 8.x** as the operating system
3. In the **Advanced** tab, find the **User data** section
4. **Copy and paste** the contents of `azure-centos-webserver-userdata.sh`
5. **Complete the VM creation** process

### 2. Azure CLI Deployment

```bash
# Create resource group
az group create --name myResourceGroup --location eastus

# Create VM with user data script
az vm create \
  --resource-group myResourceGroup \
  --name myWebServerVM \
  --image CentOS \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data azure-centos-webserver-userdata.sh \
  --size Standard_B2s \
  --public-ip-sku Standard \
  --nsg-rule SSH \
  --nsg-rule HTTP
```

### 3. Azure PowerShell Deployment

```powershell
# Create resource group
New-AzResourceGroup -Name "myResourceGroup" -Location "East US"

# Read user data script
$userData = Get-Content -Path "azure-centos-webserver-userdata.sh" -Raw
$encodedUserData = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($userData))

# Create VM configuration
$vmConfig = New-AzVMConfig -VMName "myWebServerVM" -VMSize "Standard_B2s"
$vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName "myWebServerVM" -Credential $cred -CustomData $encodedUserData
# ... additional configuration
```

### 4. ARM Template Usage

```json
{
  "type": "Microsoft.Compute/virtualMachines",
  "apiVersion": "2021-03-01",
  "properties": {
    "osProfile": {
      "customData": "[base64(parameters('userData'))]"
    }
  }
}
```

## Network Security Group Rules

Ensure your Azure Network Security Group allows the following inbound traffic:

| Port | Protocol | Source | Description |
|------|----------|--------|-------------|
| 22   | TCP      | Your IP| SSH access |
| 80   | TCP      | Any    | HTTP traffic |
| 443  | TCP      | Any    | HTTPS traffic (future use) |

## Post-Deployment Access

After deployment, you can access:

- **Main website**: `http://[your-vm-public-ip]/`
- **Server info page**: `http://[your-vm-public-ip]/info.html`

## Script Components

### 📦 Installed Packages
- `httpd` - Apache HTTP Server
- `mod_ssl` - SSL/TLS support
- `firewalld` - Firewall management
- `mod_evasive` - DDoS protection
- `dnf-automatic` - Automatic updates
- Additional utilities: `wget`, `curl`, `nano`, `vim`, `htop`

### 🔧 Configuration Files Created
- `/etc/httpd/conf.d/security.conf` - Security configurations
- `/etc/httpd/conf.d/mod_evasive.conf` - DDoS protection settings
- `/etc/logrotate.d/httpd` - Log rotation configuration
- `/usr/local/bin/webserver-maintenance.sh` - Maintenance script
- `/usr/local/bin/server-info.sh` - Server status script

### 📋 Log Files
- `/var/log/user-data.log` - User data script execution log
- `/var/log/httpd/access_log` - Apache access logs
- `/var/log/httpd/error_log` - Apache error logs
- `/var/log/webserver-maintenance.log` - Maintenance script logs

## Troubleshooting

### Check Script Execution
```bash
# View user data script execution log
sudo tail -f /var/log/user-data.log

# Check cloud-init logs
sudo tail -f /var/log/cloud-init-output.log
```

### Check Apache Status
```bash
# Check Apache service status
sudo systemctl status httpd

# Check Apache configuration
sudo httpd -t

# View Apache error logs
sudo tail -f /var/log/httpd/error_log
```

### Check Firewall
```bash
# Check firewall status
sudo firewall-cmd --state

# List allowed services
sudo firewall-cmd --list-all
```

### Manual Service Management
```bash
# Start Apache
sudo systemctl start httpd

# Enable Apache on boot
sudo systemctl enable httpd

# Restart Apache
sudo systemctl restart httpd
```

## Customization

### Modify Web Content
Edit the HTML content in the script around lines 35-95 to customize your landing page.

### Add SSL Certificate
To enable HTTPS, you'll need to:
1. Obtain an SSL certificate
2. Configure virtual hosts in Apache
3. Update firewall rules for port 443

### Additional Security
Consider adding:
- Fail2ban for intrusion prevention
- ModSecurity web application firewall
- Regular security audits with tools like Lynis

## Maintenance

The script includes automated maintenance:
- **Weekly maintenance**: Runs every Sunday at 2 AM
- **Automatic updates**: Security updates are applied automatically
- **Log rotation**: Logs are rotated daily and compressed

### Manual Maintenance
```bash
# Run maintenance script manually
sudo /usr/local/bin/webserver-maintenance.sh

# Check server information
sudo /usr/local/bin/server-info.sh
```

## Requirements

- **Azure Virtual Machine** with CentOS 8.x
- **Minimum resources**: 1 vCPU, 1 GB RAM, 10 GB disk
- **Network connectivity** for package downloads
- **Public IP** for web access (optional)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review log files for error messages
3. Ensure VM has internet connectivity for package downloads
4. Verify Network Security Group rules allow HTTP traffic

## License

This script is provided as-is for educational and production use. Please review and test thoroughly before deploying in production environments.
