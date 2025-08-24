```
mkdir ~/17.0
cd ~/17.0
```
# wkhtmltopdf
```
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
```

```
sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb
```
If you encounter any errors aer running the previous command, force install the dependencies
with the following command:
```
sudo apt-get install -f
```
# PostgreSQL
```
sudo apt install postgresql postgresql-client
```

```
sudo -u postgres createuser -d -R -S $USER
```

```
createdb $USER
```
# Git
```
git clone -b 17.0 --single-branch --depth 1 https://github.com/odoo/odoo.git
```
# Dependencies - pip
```
sudo apt install python3-pip libldap2-dev libpq-dev libsasl2-dev
```
```
sudo apt-get install nodejs npm -y 
sudo npm install -g rtlcss
```
```
python3 -m venv venv-odoo-17.0
```

```
source venv-odoo-17.0/bin/activate
```

```
pip install -r odoo/requirements.txt
```

```
deactivate
```

# Custom Apps
```
mkdir custom-apps
```
# odoo conf
```
nano odoo17.conf
```
```
[options]
; Change this admin_passwd
admin_passwd = admin_passwd

; Use the user that was created for postgres
db_user = $USER
db_password = False

addons_path = ~/17.0/odoo/addons

; Set it to False if this is internet-facing system
list_db = True
```



