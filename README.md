# Azure CentOS Web Server User Data Script

This repository contains a comprehensive user data script for automatically installing and configuring Apache HTTP Server on CentOS 8.x virtual machines in Microsoft Azure.

## Features

- ✅ **Automated Apache Installation**: Installs and configures Apache HTTP Server
- ✅ **Security Hardening**: Includes fail2ban, firewall configuration, and security headers
- ✅ **Modern Web Page**: Creates a beautiful default landing page
- ✅ **SSL Ready**: Includes helper script for Let's Encrypt SSL certificates
- ✅ **Monitoring**: Built-in status checking and log rotation
- ✅ **Production Ready**: Optimized for production environments

## What the Script Does

1. **System Updates**: Updates all system packages using DNF
2. **Apache Installation**: Installs Apache HTTP Server and essential packages
3. **Firewall Configuration**: Configures firewalld to allow HTTP/HTTPS traffic
4. **Security Setup**: 
   - Installs and configures fail2ban
   - Hides Apache version information
   - Configures security headers
5. **Web Content**: Creates a modern, responsive landing page
6. **SSL Preparation**: Includes helper script for SSL certificate installation
7. **Monitoring**: Sets up log rotation and status checking scripts

## How to Use with Azure VMs

### Method 1: Azure Portal

1. **Create VM**: Go to Azure Portal → Virtual Machines → Create
2. **Select Image**: Choose CentOS 8.x from the marketplace
3. **Configure VM**: Set your desired size, network, and other settings
4. **Advanced Tab**: 
   - Go to the "Advanced" tab
   - Under "Custom data", paste the contents of `azure-centos-webserver-userdata.sh`
5. **Create**: Complete the VM creation process

### Method 2: Azure CLI

```bash
# Create resource group
az group create --name myResourceGroup --location eastus

# Create VM with user data script
az vm create \
  --resource-group myResourceGroup \
  --name myWebServer \
  --image OpenLogic:CentOS:8_5:latest \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data azure-centos-webserver-userdata.sh \
  --size Standard_B1s
```

### Method 3: Azure PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name "myResourceGroup" -Location "East US"

# Read the script content
$userData = Get-Content -Path "azure-centos-webserver-userdata.sh" -Raw
$userDataBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($userData))

# Create VM with user data
New-AzVM `
  -ResourceGroupName "myResourceGroup" `
  -Name "myWebServer" `
  -Location "East US" `
  -ImageName "OpenLogic:CentOS:8_5:latest" `
  -Size "Standard_B1s" `
  -CustomData $userDataBase64
```

### Method 4: ARM Template

```json
{
  "type": "Microsoft.Compute/virtualMachines",
  "apiVersion": "2021-03-01",
  "name": "[parameters('vmName')]",
  "location": "[resourceGroup().location]",
  "properties": {
    "osProfile": {
      "computerName": "[parameters('vmName')]",
      "adminUsername": "[parameters('adminUsername')]",
      "customData": "[base64(parameters('userData'))]"
    }
  }
}
```

## Network Security Group Requirements

Ensure your Azure Network Security Group allows the following traffic:

```bash
# Allow SSH (port 22)
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup \
  --name AllowSSH \
  --protocol tcp \
  --priority 1000 \
  --destination-port-range 22 \
  --access allow

# Allow HTTP (port 80)
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup \
  --name AllowHTTP \
  --protocol tcp \
  --priority 1001 \
  --destination-port-range 80 \
  --access allow

# Allow HTTPS (port 443)
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNetworkSecurityGroup \
  --name AllowHTTPS \
  --protocol tcp \
  --priority 1002 \
  --destination-port-range 443 \
  --access allow
```

## Post-Deployment Verification

After the VM is created, you can verify the installation:

1. **Check VM Status**: Ensure the VM is running in Azure Portal
2. **Access Website**: Open `http://YOUR_VM_PUBLIC_IP` in a browser
3. **SSH to VM**: Connect via SSH to check logs and status

```bash
# SSH to your VM
ssh azureuser@YOUR_VM_PUBLIC_IP

# Check the setup log
sudo cat /var/log/webserver-setup.log

# Run the status check script
sudo /root/check-webserver.sh

# Check Apache status
sudo systemctl status httpd
```

## File Structure After Installation

```
/var/www/html/                 # Web root directory
├── index.html                 # Default landing page

/etc/httpd/                    # Apache configuration
├── conf/httpd.conf           # Main Apache config
├── conf.d/default.conf       # Virtual host config
└── conf.d/security.conf      # Security settings

/var/log/httpd/               # Apache logs
├── access.log                # Access logs
└── error.log                 # Error logs

/root/                        # Helper scripts
├── check-webserver.sh        # Status checking script
└── setup-ssl.sh             # SSL certificate helper
```

## SSL Certificate Setup

To add SSL certificates after deployment:

```bash
# SSH to your VM
ssh azureuser@YOUR_VM_PUBLIC_IP

# Run the SSL setup helper (as root)
sudo /root/setup-ssl.sh

# Follow the prompts to install certbot, then run:
sudo certbot --apache -d your-domain.com

# Set up automatic renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

## Customization

### Adding Your Own Website

Replace the default content:

```bash
# Remove default page
sudo rm /var/www/html/index.html

# Upload your website files to /var/www/html/
# Set proper permissions
sudo chown -R apache:apache /var/www/html/
sudo chmod -R 755 /var/www/html/
```

### Adding Virtual Hosts

Create additional virtual hosts:

```bash
# Create new virtual host config
sudo nano /etc/httpd/conf.d/mysite.conf

# Restart Apache
sudo systemctl restart httpd
```

## Troubleshooting

### Common Issues

1. **Website not accessible**: Check Network Security Group rules
2. **Apache not starting**: Check logs with `sudo journalctl -u httpd`
3. **Permission errors**: Ensure proper ownership with `sudo chown -R apache:apache /var/www/html/`

### Useful Commands

```bash
# Check Apache status
sudo systemctl status httpd

# View Apache logs
sudo tail -f /var/log/httpd/access.log
sudo tail -f /var/log/httpd/error.log

# Test Apache configuration
sudo httpd -t

# Check firewall status
sudo firewall-cmd --list-all

# Check fail2ban status
sudo fail2ban-client status
```

## Security Features

- **Fail2ban**: Protects against brute force attacks
- **Firewall**: Only allows necessary ports (22, 80, 443)
- **Server Signature**: Disabled to hide Apache version
- **Security Headers**: Configured to prevent common attacks
- **Log Rotation**: Prevents log files from consuming too much space

## Requirements

- Azure subscription
- CentOS 8.x virtual machine
- Network Security Group allowing HTTP/HTTPS traffic
- Public IP address (optional, for internet access)

## Support

For issues related to:
- **Azure VM**: Check Azure documentation or contact Azure support
- **CentOS**: Refer to CentOS documentation
- **Apache**: Check Apache HTTP Server documentation
- **This Script**: Review the setup log at `/var/log/webserver-setup.log`

## License

This script is provided as-is for educational and production use. Modify as needed for your specific requirements.
