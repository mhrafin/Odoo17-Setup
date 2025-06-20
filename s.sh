#--------------------------------------------------
# 
#--------------------------------------------------
echo -e "\n\n----  ----"

#--------------------------------------------------
# Variables
#--------------------------------------------------
OE_USER="odoo17"
OE_VERSION="17.0"

#--------------------------------------------------
# Update the Server
#--------------------------------------------------
echo -e "\n\n---- Update the Server ----"
sudo apt-get update
sudo apt-get upgrade -y

#--------------------------------------------------
# Install Packages and Libraries
#--------------------------------------------------
echo -e "\n\n---- Install Packages and Libraries ----"

sudo apt-get install -y python3-pip
sudo apt-get install -y python3-dev libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libmysqlclient-dev libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev
sudo apt-get install -y nodejs npm

# Create a Symlink for Node.js: Sometimes, Node.js is installed as nodejs but some applications expect node. Create a symlink to ensure compatibility.
sudo ln -s /usr/bin/nodejs /usr/bin/node

sudo npm install -g less less-plugin-clean-css
sudo apt-get install -y node-less

#--------------------------------------------------
# Set Up the Database Server
#--------------------------------------------------
echo -e "\n\n---- Set Up the Database Server ----"
DB_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
sudo apt-get install -y postgresql
sudo -u postgres psql -c "CREATE ROLE $OE_USER WITH CREATEDB LOGIN SUPERUSER PASSWORD '$DB_PASS';"


#--------------------------------------------------
# Create a System User for Odoo
#--------------------------------------------------
echo -e "\n\n---- Create a System User for Odoo ----"
sudo adduser --system --home=/opt/$OE_USER --group $OE_USER


#--------------------------------------------------
# Get Odoo 17 Community Edition from GitHub
#--------------------------------------------------
echo -e "\n\n---- Get Odoo 17 Community Edition from GitHub ----"
sudo apt-get install -y git

# Assume the home directory or target install directory is already set (e.g., /opt/$OE_USER)
sudo -u $OE_USER -H bash -c "git clone https://www.github.com/odoo/odoo --depth 1 --branch $OE_VERSION --single-branch /opt/$OE_USER"


#--------------------------------------------------
# Install Required Python Packages
#--------------------------------------------------
echo -e "\n\n---- Install Required Python Packages ----"
sudo apt install -y python3-venv
sudo python3 -m venv /opt/$OE_USER/venv

# Activate venv and install dependencies as the $OE_USER user
sudo -u $OE_USER -H bash -c "
  source /opt/$OE_USER/venv/bin/activate && \
  pip install -r /opt/$OE_USER/requirements.txt
"

wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6-1.jammy_amd64.deb || true
sudo apt install -f -y

#--------------------------------------------------
# Set Up the Configuration File
#--------------------------------------------------
echo -e "\n\n---- Set Up the Configuration File ----"
sudo touch /etc/$OE_USER.conf

OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

sudo tee /etc/$OE_USER.conf > /dev/null <<EOF
[options]
; This is the password that allows database operations:
admin_passwd = $OE_SUPERADMIN
db_host = False
db_port = False
db_user = $OE_USER
db_password = False
addons_path = /opt/$OE_USER/addons
default_productivity_apps = True
logfile = /var/log/odoo/$OE_USER.log
EOF

sudo chown $OE_USER: /etc/$OE_USER.conf
sudo chmod 640 /etc/$OE_USER.conf

sudo mkdir -p /var/log/odoo
sudo chown $OE_USER:root /var/log/odoo


#--------------------------------------------------
# Setup the Service File
#--------------------------------------------------
echo -e "\n\n---- Setup the Service File ----"
sudo tee /etc/systemd/system/$OE_USER.service > /dev/null <<EOF
[Unit]
Description=$OE_USER
Documentation=http://www.odoo.com
[Service]
# Ubuntu/Debian convention:
Type=simple
User=$OE_USER
ExecStart=/opt/$OE_USER/venv/bin/python3 /opt/$OE_USER/odoo-bin -c /etc/$OE_USER.conf
[Install]
WantedBy=default.target
EOF

sudo chmod 755 /etc/systemd/system/$OE_USER.service
sudo chown root: /etc/systemd/system/$OE_USER.service

sudo systemctl daemon-reload
sudo systemctl enable $OE_USER.service
sudo systemctl start $OE_USER.service

# You can view the real-time logs in the terminal by using this command.
#echo "sudo tail -f /var/log/odoo/$OE_USER.log"

echo "-----------------------------------------------------------"
echo "Password superadmin (database): $OE_SUPERADMIN"
echo "PostgreSQL user Password      : $DB_PASS"
echo "-----------------------------------------------------------"