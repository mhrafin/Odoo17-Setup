#!/bin/bash

# Updating Ubuntu and Installing the First Set of Required Packages
sudo apt update
sudo apt upgrade -y

sudo apt install postgresql postgresql-client build-essential python3-pillow python3-lxml python3-dev python3-pip python3-setuptools npm nodejs git gdebi libldap2-dev libsasl2-dev libxml2-dev python3-wheel python3-venv libxslt1-dev node-less libjpeg-dev libpq-dev -y

# For languages using a right-to-left interface (such as Arabic or Hebrew), the rtlcss package is required.
sudo npm install -g rtlcss

# Creating a System User
sudo useradd -m -d /opt/odoo17 -U -r -s /bin/bash odoo17

# Configuring PostgreSQL
sudo su - postgres -c "createuser -s odoo17"

# Installing Wkhtmltopdf
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb

sudo apt install ./wkhtmltox_0.12.6.1-3.jammy_amd64.deb -y


# Downloading, Installing, and Configuring Odoo 17 in a Virtual Environment
sudo -u odoo17 -H git clone https://www.github.com/odoo/odoo --depth 1 --branch 17.0 /opt/odoo17/odoo
sudo -u odoo17 -H python3 -m venv /opt/odoo17/odoo-venv

# Install the Required Odoo Python dependencies
sudo -u odoo17 -H /opt/odoo17/odoo-venv/bin/pip install wheel
sudo -u odoo17 -H /opt/odoo17/odoo-venv/bin/pip install -r /opt/odoo17/odoo/requirements.txt

# Creating a configuration file for our Odoo installation
sudo tee /etc/odoo17.conf > /dev/null <<EOF
[options]
; Specify the password that allows database management:
admin_passwd = scrpass
db_host = False
db_port = False
db_user = odoo17
db_password = False
addons_path = /opt/odoo17/odoo/addons
; This is the default port. It is specified here as you will want to set this if you are running Odoo on an alternate port.
xmlrpc_port = 8069
; This is the default longpolling port. Like the xmlrpc_port we are specifying this port for completeness
longpolling_port = 8072
; If you plan on setting up nginx it is advised to specify multiple workers in the configuration. If you don’t set this to workers > 1 then you could run into problems when you specify the long polling blocks in the nginx config file.
workers = 2
; You will want to add a dbfilter to your config file if you have more than one database. The ; means the command is commented out. Remove the ; and specify the database so that your Odoo installation knows exactly which database to use for the instance.
; dbfilter = [your database]
EOF

# Creating a Systemd unit file to auto-start Odoo when the server reboots
sudo tee /etc/systemd/system/odoo17.service > /dev/null <<EOF
[Unit]
Description=Odoo17
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo17
PermissionsStartOnly=true
User=odoo17
Group=odoo17
ExecStart=/opt/odoo17/odoo-venv/bin/python3 /opt/odoo17/odoo/odoo-bin -c /etc/odoo17.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl enable --now odoo17

sudo systemctl status odoo17