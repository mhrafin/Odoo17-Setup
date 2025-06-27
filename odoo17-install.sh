#!/bin/bash

# This script was specifically tested for odoo community version 17.0 on ubuntu 24.04 server.



############################################# Variables ##################################################
OC_USER="odoo17"

# Set this to "False" if you are just installing Odoo 17.0 CE for development purpose
ODOO_THROUGH_DOMAIN="True"

# Change this to a legit domain you own. Be sure to setup DNS Records on your domain registrar.
# You should at least have this two in your DNS Records
# |  Name                 | Type     | Value                            |
# | --------------------- | -------- | -------------------------------- |
# | YOURWEBSITE.COM       | A        | `Your VPS IP`                    |
# | www.YOURWEBSITE.COM   | A        | `Your VPS IP` or YOURWEBSITE.COM |
YOURWEBSITE="YOURWEBSITE.COM"

##########################################################################################################

# Its better if you update and upgrade your system before running this script, 
# so that you can make sure you are running the up-to-date kernel version.
# Updating Ubuntu and Installing the First Set of Required Packages
sudo apt update
sudo apt upgrade -y

sudo apt install postgresql postgresql-client build-essential python3-pillow python3-lxml python3-dev python3-pip python3-setuptools npm nodejs git gdebi libldap2-dev libsasl2-dev libxml2-dev python3-wheel python3-venv libxslt1-dev node-less libjpeg-dev libpq-dev -y

# For languages using a right-to-left interface (such as Arabic or Hebrew), the rtlcss package is required.
sudo npm install -g rtlcss

# Creating a System User
sudo useradd -m -d /opt/$OC_USER -U -r -s /bin/bash $OC_USER

# Configuring PostgreSQL
sudo su - postgres -c "createuser -s $OC_USER"

# Installing Wkhtmltopdf
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb

sudo mv ~/wkhtmltox_0.12.6.1-3.jammy_amd64.deb /tmp/
sudo apt install /tmp/wkhtmltox_0.12.6.1-3.jammy_amd64.deb -y


# Downloading, Installing, and Configuring Odoo 17 in a Virtual Environment
sudo -u $OC_USER -H git clone https://www.github.com/odoo/odoo --depth 1 --branch 17.0 /opt/$OC_USER/odoo
sudo -u $OC_USER -H python3 -m venv /opt/$OC_USER/odoo-venv

# Install the Required Odoo Python dependencies
sudo -u $OC_USER -H /opt/$OC_USER/odoo-venv/bin/pip install wheel
sudo -u $OC_USER -H /opt/$OC_USER/odoo-venv/bin/pip install -r /opt/$OC_USER/odoo/requirements.txt

# Creating a configuration file for our Odoo installation
sudo tee /etc/$OC_USER.conf > /dev/null <<EOF
[options]
; Specify the password that allows database management:
admin_passwd = scrpass
db_host = False
db_port = False
db_user = $OC_USER
db_password = False
addons_path = /opt/$OC_USER/odoo/addons
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
sudo tee /etc/systemd/system/$OC_USER.service > /dev/null <<EOF
[Unit]
Description=$OC_USER
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=$OC_USER
PermissionsStartOnly=true
User=$OC_USER
Group=$OC_USER
ExecStart=/opt/$OC_USER/odoo-venv/bin/python3 /opt/$OC_USER/odoo/odoo-bin -c /etc/$OC_USER.conf
StandardOutput=journal+console
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl enable --now $OC_USER.service

sudo systemctl status $OC_USER.service --no-pager

###############################################################################################################################

if [ $ODOO_THROUGH_DOMAIN = "False"]; then
    sudo journalctl -u $OC_USER.service -f
    exit 0
fi

echo "Continuing to configuring Nginx to access Odoo through a secured SSL domain name"

# Configuring Nginx to access Odoo through a secured SSL domain name
# Installing Nginx
sudo apt install nginx -y

sudo systemctl status nginx --no-pager

# Getting and Installing your FREE SSL Certificate
# Install the Certbot package
sudo apt install certbot -y

sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

# Obtaining the SSL certificate
sudo mkdir -p /var/lib/letsencrypt/.well-known

sudo chgrp www-data /var/lib/letsencrypt

sudo chmod g+s /var/lib/letsencrypt

# Creating code snippets to hold our SSL configuration details
sudo tee /etc/nginx/snippets/letsencrypt.conf > /dev/null <<EOF
location ^~ /.well-known/acme-challenge/ {
    allow all;
    root /var/lib/letsencrypt/;
    default_type "text/plain";
    try_files \$uri =404;
}
EOF

sudo tee /etc/nginx/snippets/ssl.conf > /dev/null <<EOF
ssl_dhparam /etc/ssl/certs/dhparam.pem;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-
AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-
RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-
ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-
SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-
RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-
RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-
SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-
SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
ssl_prefer_server_ciphers on;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 30s;
add_header Strict-Transport-Security "max-age=15768000; includeSubdomains; preload";
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;
EOF

# HERE IS WHERE YOU START FOR ADDING DOMAINS TO AN EXISTING INSTANCE
sudo tee /etc/nginx/sites-available/$YOURWEBSITE > /dev/null <<EOF
server {
    listen 80;
    server_name $YOURWEBSITE www.$YOURWEBSITE;
    include snippets/letsencrypt.conf;
}
EOF

sudo ln -s /etc/nginx/sites-available/$YOURWEBSITE /etc/nginx/sites-enabled/

sudo systemctl restart nginx

sudo certbot certonly --agree-tos --no-eff-email --email admin@$YOURWEBSITE --webroot -w /var/lib/letsencrypt/ -d $YOURWEBSITE -d www.$YOURWEBSITE

#######################################################################################################
#               You see the below message you are all good, if not start debugging!                   #
#######################################################################################################
#                                                                                                     #
#   Saving debug log to /var/log/letsencrypt/letsencrypt.log                                          #
#   Requesting a certificate for $YOURWEBSITE and www.$YOURWEBSITE                                    #
                                                                                                      #
#   Successfully received certificate.                                                                #
#   Certificate is saved at: /etc/letsencrypt/live/$YOURWEBSITE/fullchain.pem                         #
#   Key is saved at:         /etc/letsencrypt/live/$YOURWEBSITE/privkey.pem                           #
#   This certificate expires on 2025-09-25.                                                           #
#   These files will be updated when the certificate renews.                                          #
#   Certbot has set up a scheduled task to automatically renew this certificate in the background.    #
                                                                                                      #
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -                   #
#   If you like Certbot, please consider supporting our work by:                                      #
#    * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate                             #
#    * Donating to EFF:                    https://eff.org/donate-le                                  #
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -                   #
#                                                                                                     #
#######################################################################################################


# Modifying your Nginx configuration to access your Odoo installation with the SSL certificate
sudo tee /etc/nginx/sites-available/$YOURWEBSITE > /dev/null <<EOF
# Odoo servers
upstream odooserver {
    server 127.0.0.1:8069;
}

upstream odoochat {
    server 127.0.0.1:8072;
}

# HTTP -> HTTPS
server {
    listen [::]:80;
    listen 80;
    server_name www.$YOURWEBSITE $YOURWEBSITE;
    return 301 https://$YOURWEBSITE\$request_uri;
}

# WWW -> NON WWW
server {
    listen [::]:443 ssl;
    listen 443 ssl http2;
    server_name www.$YOURWEBSITE;

    ssl_certificate /etc/letsencrypt/live/$YOURWEBSITE/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$YOURWEBSITE/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$YOURWEBSITE/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    return 301 https://$YOURWEBSITE\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name $YOURWEBSITE;

    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    # Proxy headers
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;

    # SSL parameters
    ssl_certificate /etc/letsencrypt/live/$YOURWEBSITE/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$YOURWEBSITE/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$YOURWEBSITE/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    # log files
    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;

    # Specifies the maximum accepted body size of a client request,
    # as indicated by the request header Content-Length.
    client_max_body_size 200m;

    # increase proxy buffer to handle some odoo web requests
    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    # Handle longpoll requests
    location /longpolling {
        proxy_pass http://odoochat;
    }

    # Handle / requests
    location / {
        proxy_redirect off;
        proxy_pass http://odooserver;
    }

    # Cache static files
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odooserver;
    }

    # Gzip
    gzip_types text/css text/less text/plain text/xml application/xml
    application/json application/javascript;
    gzip on;
}
EOF

sudo systemctl restart nginx

# Change the Odoo Configuration File to use proxy mode
sudo tee /etc/$OC_USER.conf > /dev/null <<EOF
[options]
; Specify the password that allows database management:
admin_passwd = scrpass
db_host = False
db_port = False
db_user = $OC_USER
db_password = False
addons_path = /opt/$OC_USER/odoo/addons
; This is the default port. It is specified here as you will want to set this if you are running Odoo on an alternate port.
xmlrpc_port = 8069
; This is the default longpolling port. Like the xmlrpc_port we are specifying this port for completeness
longpolling_port = 8072
; If you plan on setting up nginx it is advised to specify multiple workers in the configuration. If you don’t set this to workers > 1 then you could run into problems when you specify the long polling blocks in the nginx config file.
workers = 2
; You will want to add a dbfilter to your config file if you have more than one database. The ; means the command is commented out. Remove the ; and specify the database so that your Odoo installation knows exactly which database to use for the instance.
; dbfilter = [your database]
proxy_mode = True
EOF

# sudo tee /etc/$OC_USER.conf > /dev/null <<EOF
# [options]
# ; Specify the password that allows database management:
# admin_passwd = scrpass
# db_user = $OC_USER
# db_password = False
# addons_path = /opt/$OC_USER/odoo/addons
# ; If you plan on setting up nginx it is advised to specify multiple workers in the configuration. If you don’t set this to workers > 1 then you could run into problems when you specify the long polling blocks in the nginx config file.
# workers = 2
# proxy_mode = True
# EOF


sudo systemctl restart $OC_USER

sudo journalctl -u $OC_USER --no-pager -n 50