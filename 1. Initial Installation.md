# System Update
```
sudo apt update && sudo apt upgrade - y
```

# Install Necessary Packages
```
sudo apt install postgresql postgresql-server-dev-all build-essential python3-pillow python3-lxml python3-dev python3-pip python3-setuptools npm nodejs git gdebi libldap2-dev libsasl2-dev libxml2-dev python3-wheel python3-venv libxslt1-dev node-less libjpeg-dev -y
```

# Check the PostgreSQL version
```
psql --version
```
Remember the version.

## Start PostgreSQL main cluster
If the version of PostgreSQL was 16.2 or any 16.x or any version like 14.x, just use the whole INT number.
```
sudo pg_ctlcluster 16 main start
```

# Create a new Linux user account
```
sudo useradd -m -d /opt/odoo17 -U -r -s /bin/bash odoo17
```

Here,

`-m`: Creates the user's home directory if it doesn't exist

`-d /opt/odoo17`: Sets the home directory path to `/opt/odoo17` (non-standard location)

`-U`: Creates a group with the same name as the user and adds the user to that group

`-r` Creates a system account:

- This creates a "system account" instead of a regular user account
- System accounts are meant for running services or programs, not for human users
- They typically have lower user ID numbers (usually below 1000)
- They often don't show up in login screens or user lists
- Think of it like creating an account specifically for a program (in this case, Odoo) rather than for a person

`-s /bin/bash` Sets the user's login shell to bash:

- This sets which program runs when the user logs in
- `/bin/bash` is the standard command-line interface (shell) on many Linux systems
- This means the odoo17 user can use normal terminal commands if someone logs in as that user
- Without this, the account might be limited in what it can do when logged in
- It's useful for troubleshooting or manual maintenance of the Odoo service

# Create a new PostgreSQL database user
This command creates a PostgreSQL superuser named "odoo17" by temporarily becoming the Postgres system user.
```
sudo su - postgres -c "createuser -s odoo17"
```

Here,

`su -` switches to another user with a login shell environment
`postgres` is the target user, which is the PostgreSQL system user.

`-c "createuser -s odoo17"` - This executes a command as the postgres user:

- `createuser` is a PostgreSQL utility to create new database users
- `-s` flag gives the new user superuser privileges in PostgreSQL. The superuser privilege is significant because it allows the odoo17 user to create databases, roles, and have unrestricted access to all databases in the PostgreSQL server.
- `odoo17` is the name of the user being created

# Downloading wkhtmltopdf .deb file
```
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
```

## Install wkhtmltopdf
```
sudo apt install ./wkhtmltox_0.12.6.1-2.jammy_amd64.deb
```
# Switch to odoo17 Linux user account
```
sudo su - odoo17
```

## Clone odoo17 repo
This command is downloading the latest code from the Odoo version 17.0 branch, without its commit history, and placing it in the `/opt/odoo17/odoo` directory on your system.
```
git clone https://www.github.com/odoo/odoo --depth 1 --branch 17.0 /opt/odoo17/odoo
```

`--depth 1`: This flag creates a "shallow clone" with a history truncated to only the most recent commit. Instead of downloading the entire commit history (which can be large), this only gets the latest version, saving bandwidth and storage space.

## Change directory to 
```
cd /opt/odoo17
```

## Create a Python virtual environment
```
python3 -m venv odoo-venv
```

## Activate the Python virtual environment
```
source odoo-venv/bin/activate
```

### Install wheel
```
pip3 install wheel
```

### Install Odoo's requirements
```
pip3 install -r odoo/requirements.txt
```
### Change directory to Odoo cloned repo
```
cd /opt/odoo17/odoo
```

### Start Odoo
```
./odoo-bin
```

Odoo is now running on localhost:8069 unless the port 8069 is already is in use.
Check localhost:8069. Do not do anything yet.

### Stop Odoo
 Press `ctrl + c` to stop Odoo.

## Deactivate Python venv
```
deactivate
```

## Make directory for custom Odoo addons
```
mkdir /opt/odoo17/odoo-custom-addons
```

# Exit odoo17 Linux user account
```
exit
```

