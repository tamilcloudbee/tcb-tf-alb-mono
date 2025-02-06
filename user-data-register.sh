#!/bin/bash

# Update package list and install necessary packages
apt update -y
apt upgrade -y

# Install Apache2 and Git
apt install apache2 git -y

# Start Apache2 service
systemctl start apache2
systemctl enable apache2

# Clone the website repository into the Apache web directory
cd /var/www/html
rm -rf *   # Remove the default Apache welcome page
git clone  https://github.com/tamilcloudbee/tcb-web-app.git .  # Replace with your Git repo URL
# rm -rf admin
# Set correct permissions
chown -R www-data:www-data /var/www/html

# Restart Apache to ensure the new content is served
systemctl restart apache2
