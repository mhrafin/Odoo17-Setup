# System Update

```
sudo apt update && sudo apt upgrade -y
```

# Install Necessary Packages

```
sudo apt install postgresql postgresql-server-dev-all build-essential python3-pillow python3-lxml python3-dev python3-pip python3-setuptools npm nodejs git libldap2-dev libsasl2-dev libxml2-dev python3-wheel python3-venv libxslt1-dev node-less libjpeg-dev libssl-dev libffi-dev fontconfig libxrender1 xfonts-75dpi xfonts-base -y
```

# Downloading wkhtmltopdf .deb file

```
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
```

## Install wkhtmltopdf

```
sudo mv ~/wkhtmltox_0.12.6.1-2.jammy_amd64.deb /tmp/
sudo apt install /tmp/wkhtmltox_0.12.6.1-2.jammy_amd64.deb -y
```

# Create a new PostgreSQL database user

This command creates a PostgreSQL superuser named "odoodev" (**IF YOU DECIDE TO USE A DIFFERENT NAME, BE SURE TO USE THAT ON THE LATER COMMANDS WHERE I USE 'odoodev'**) by temporarily becoming the Postgres system user.

```
sudo su - postgres -c "createuser -s odoodev"
```

Here,

`su -` switches to another user with a login shell environment
`postgres` is the target user, which is the default PostgreSQL admin user. (Auto created during postgresql installation.)

`-c "createuser -s odoodev"` - This executes a command as the postgres user:

- `createuser` is a PostgreSQL utility to create new database users
- `-s` flag gives the new user superuser privileges in PostgreSQL. The superuser privilege is significant because it allows the odoodev user to create databases, roles, and have unrestricted access to all databases in the PostgreSQL server.
- `odoodev` is the name of the user being created

## Configure PostgreSQL database

```
sudo su postgres
```

```
psql
```

```
ALTER USER odoodev WITH PASSWORD 'your_password';
```

**REMEMBER TO CHANGE 'your_password' TO SOMETHING GOOD AND WHICH YOU CAN REMEMBER**.

```
\q
```

```
exit
```

# Clone odoo17 repo

This command is downloading the latest code from the Odoo version 17.0 branch, without its commit history, and placing it in the `~/odoodevelopment/17.0/` directory on your system.

```
git clone https://www.github.com/odoo/odoo --depth 1 --branch 17.0 ~/odoodevelopment/17.0/
```

`--depth 1`: This flag creates a "shallow clone" with a history truncated to only the most recent commit. Instead of downloading the entire commit history (which can be large), this only gets the latest version, saving bandwidth and storage space.

# Change directory to

```
cd ~/odoodevelopment/17.0/
```

# Create a Python virtual environment

```
python3 -m venv odoo17-venv
```

## Activate the Python virtual environment

```
source odoo17-venv/bin/activate
```

### Install wheel

```
pip3 install wheel
```

### Install openpyxl

```
pip3 install openpyxl
```

### Install Odoo's requirements

```
pip3 install -r requirements.txt
```

## Deactivate Python venv

```
deactivate
```

## Create Odoo Config file

```
nano ~/odoodevelopment/17.0/odoo.conf
```

Paste the below code there, **Remember to change the admin_passwd to something good**.

```
[options]
; The ; means the command is commented out.


; Change this password to something good and which you can remember.
; Specify the password that allows database management:
admin_passwd = admin_passwd


; This is the odoodev postgresql database user we created earlier.
db_user = odoodev
; This is the odoodev database user's password we set earlier. Change it what you set.
db_password = your_password

addons_path = ~/odoodevelopment/17.0/addons,~/odoodevelopment/17.0/myapps
```

## Make directory for custom Odoo addons named 'myapps'

```
mkdir ~/odoodevelopment/17.0/myapps
```

# Edit pg_hba.conf

To locate where this pg_hba.conf file is, use this 
To use 'locate' command you need to install plocate, 

```
sudo apt install plocate -y
```

```
locate pg_hba.conf
```



- Copy the first location. It probably looks like this, `/etc/postgresql/16/main/pg_hba.conf`

- Sudo nano into the file,

```
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

- Find this line in the file scrolling down, (I suggest read the file if possible)

```
local   all             all                                     peer
```

![image of the file](<img/2a1.jpg>)

- change 'peer' to 'md5'

- Press ctrl + o then press Enter key to save. Press ctrl + x to exit.

- Restart postgresql service and reload daemon and again restart postgresql service.

```
sudo systemctl restart postgresql
sudo systemctl daemon-reload
sudo systemctl restart postgresql
```

# Install Pycharm

Follow the instruction from this [Link](https://www.jetbrains.com/help/pycharm/installation-guide.html).

Now that pycharm is install in your linux system. Lets Continue,

# Open odoo17 folder

Open the "~/odoodevelopment/17.0/" folder on pycharm.
Here ~ means your user's home directory, usually its `/home/your_user_name/`.
You can find your user name with this,
```
whoami
```

## Set python interpreter

After opening the 17.0 folder on pycharm, if it doesn't detect interpreter specifically from `~/odoodevelopment/17.0/odoo17-venv` (We created this previously) then first try restarting pycharm, if it still doesn't get the interpreter from there then add the interpreter located in `~/odoodevelopment/17.0/odoo17-venv/bin/python` manually.

# Create a configuration

- Go to `Run > Edit Configuration` from the navbar of pycharm.
- Click on the '+' sign and select python. On the script field select the odoo-bin file located in  `~/odoodevelopment/17.0/odoo-bin`
- On Script parameters field add the conf you created earlier. Like this, `-c /path/to/your/conf/file.conf` . Those who followed the instructions copy paste this,

```
-c /home/your_user_name/odoodevelopment/17.0/odoo.conf
```

- Set the working directory to `~/odoodevelopment/17.0/`
- keep everything else as is and click apply and close.
- Run the config and goto localhost:8069 on your browser.
