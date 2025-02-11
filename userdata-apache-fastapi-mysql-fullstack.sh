#!/bin/bash

exec > /var/log/userdata.log 2>&1

echo "Starting user-data script execution..."

# Function to retry a command up to 5 times with backoff
retry_command() {
    local retries=5
    local count=0
    local delay=10
    local command=$1
    until $command; do
        ((count++))
        if [ $count -ge $retries ]; then
            echo "Command failed after $count attempts: $command"
            return 1
        fi
        echo "Command failed. Retrying ($count/$retries)..."
        sleep $delay
    done
}

# Update package list and install required packages
echo "Updating packages..."
retry_command "apt update -y"

echo "Installing Apache, MySQL, Python3, Git, curl, net-tools, and dependencies..."
retry_command "apt install -y apache2 mysql-server python3 python3-pip git libmysqlclient-dev ufw curl net-tools python3-venv"

# Disable UFW
echo "Disabling UFW..."
systemctl stop ufw
systemctl disable ufw

# Enable and start Apache & MySQL
echo "Enabling and starting Apache & MySQL..."
systemctl enable apache2 mysql
systemctl start apache2 mysql

# Secure MySQL and configure database
echo "Configuring MySQL root user and database..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Root@123'; FLUSH PRIVILEGES;"
mysql -u root -pRoot@123 -e "CREATE DATABASE tcb_db;"
mysql -u root -pRoot@123 -e "CREATE USER 'tcbadmin'@'localhost' IDENTIFIED BY 'Tcb@2025';"
mysql -u root -pRoot@123 -e "GRANT ALL PRIVILEGES ON tcb_db.* TO 'tcbadmin'@'localhost'; FLUSH PRIVILEGES;"

# Create `tcb_enquiry` table and add `course` field
echo "Creating `tcb_enquiry` table and adding 'course' column..."
mysql -u tcbadmin -pTcb@2025 -D tcb_db -e "
CREATE TABLE IF NOT EXISTS tcb_enquiry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    course VARCHAR(255) NOT NULL,  # Added 'course' column
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"

# Clone and deploy website
echo "Cloning website repository..."
rm -rf /var/www/html/*
git clone https://github.com/tamilcloudbee/tcb-web-app /var/www/html
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Set up Python virtual environment for FastAPI
echo "Setting up Python virtual environment..."
mkdir -p /var/www/fastapi
cd /var/www/fastapi
python3 -m venv venv
source venv/bin/activate

# Install FastAPI, Gunicorn, Uvicorn, pymysql, python-multipart in the virtual environment
echo "Installing FastAPI, Gunicorn, Uvicorn, pymysql, and python-multipart..."
pip install fastapi pymysql gunicorn uvicorn python-multipart

# Create FastAPI app with 'course' field handling
cat <<EOF > /var/www/fastapi/main.py
from fastapi import FastAPI, Form
from fastapi.middleware.cors import CORSMiddleware
import pymysql

app = FastAPI()

# CORS Middleware to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins. Replace with specific domains if necessary.
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allow all headers
)

def get_db_connection():
    return pymysql.connect(
        host="localhost",
        user="tcbadmin",
        password="Tcb@2025",
        database="tcb_db"
    )

@app.post("/register/")
async def submit_form(
    name: str = Form(...), 
    email: str = Form(...), 
    phone: str = Form(...), 
    message: str = Form(...),
    course: str = Form(...),  # Added course field
):
    # Open database connection
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Insert the form data into the database
        cursor.execute(
            "INSERT INTO tcb_enquiry (name, email, phone, message, course) VALUES (%s, %s, %s, %s, %s)",
            (name, email, phone, message, course)  # Insert course field
        )
        conn.commit()  # Commit the changes
    except Exception as e:
        conn.rollback()  # Rollback in case of an error
        return {"status": "error", "message": f"Error saving data: {str(e)}"}
    finally:
        cursor.close()
        conn.close()
    
    # Return success response
    return {"status": "success", "message": "Data saved successfully"}

@app.get("/enquiries/")
async def get_enquiries():
    # Open database connection
    conn = get_db_connection()
    cursor = conn.cursor(pymysql.cursors.DictCursor)  # Using DictCursor to get results as dictionaries
    
    try:
        # Retrieve all the enquiries from the database
        cursor.execute("SELECT * FROM tcb_enquiry")
        rows = cursor.fetchall()  # Get all the rows
        
        # Return the rows as a JSON response
        return rows
    
    except Exception as e:
        return {"status": "error", "message": f"Error fetching data: {str(e)}"}
    
    finally:
        cursor.close()
        conn.close()

EOF

# Create systemd service for Gunicorn
echo "Creating Gunicorn service..."
cat <<EOF > /etc/systemd/system/fastapi.service
[Unit]
Description=FastAPI with Gunicorn Service
After=network.target

[Service]
User=root
WorkingDirectory=/var/www/fastapi
ExecStart=/var/www/fastapi/venv/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start FastAPI service
echo "Starting FastAPI service..."
systemctl daemon-reload
systemctl enable fastapi
systemctl start fastapi

# Get the public IP address of the EC2 instance
#echo "Fetching public IP address..."
#retry_command "PUBLIC_IP=\$(retry_command "PUBLIC_IP=\$(curl ifconfig.me)""


# Update the register/index.html file with the EC2's public IP (pointing to FastAPI on port 8000)
#echo "Updating the register form with the public IP..."
#sed -i "s|your-alb-url.com|$PUBLIC_IP:8000|g" /var/www/html/register/index.html

# Configure Apache to serve static files and reverse proxy FastAPI
echo "Configuring Apache..."
cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    # Serve static content from /admin
    Alias /admin /var/www/html/admin
    <Directory /var/www/html/admin>
        AllowOverride All
        Require all granted
    </Directory>

    # Serve static content from /register
    Alias /register /var/www/html/register
    <Directory /var/www/html/register>
        AllowOverride All
        Require all granted
    </Directory>

    # Reverse proxy FastAPI
    ProxyPass /api http://127.0.0.1:8000/
    ProxyPassReverse /api http://127.0.0.1:8000/

</VirtualHost>
EOF

# Enable necessary Apache modules and restart Apache
a2enmod proxy proxy_http
systemctl restart apache2

# Verify installation
echo "Verifying installation..."

echo "Checking installed packages..."
dpkg -l | grep -E "apache2|mysql-server|python3|git|curl|net-tools"

echo "Checking running services..."
systemctl status apache2 mysql fastapi --no-pager

echo "Checking database and table..."
mysql -u tcbadmin -pTcb@2025 -D tcb_db -e "SHOW TABLES;"

# Update the register/index.html file with the EC2's public IP (pointing to FastAPI on port 8000)
echo "Updating the register form with the public IP..."
sleep 60

PUBLIC_IP=$(curl ifconfig.me)

sudo sed -i "s/your-alb-url.com/$PUBLIC_IP:8000/g" /var/www/html/register/index.html
sudo sed -i "s/your-alb-url.com/$PUBLIC_IP:8000/g" /var/www/html/admin/index.html

echo "User-data script execution completed."
