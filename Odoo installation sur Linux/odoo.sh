#!/bin/bash

# Script d'installation d'Odoo 14 Community

# Vérification des permissions
if [ "$EUID" -ne 0 ]; then
    echo "Veuillez exécuter ce script en tant qu'utilisateur root."
    exit 1
fi

echo "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

echo "Installation des paquets requis..."
sudo apt install -y \
    postgresql postgresql-server-dev-10 build-essential python3-pillow python3-lxml python3-dev \
    python3-pip python3-setuptools npm nodejs git gdebi libldap2-dev libsasl2-dev libxml2-dev \
    python3-wheel python3-venv libxslt1-dev node-less libjpeg-dev zlib1g-dev libpq-dev \
    libtiff5-dev libjpeg8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev \
    libfribidi-dev libxcb1-dev

echo "Démarrage du service PostgreSQL..."
sudo pg_ctlcluster 10 main start

echo "Création des répertoires nécessaires pour Odoo..."
sudo mkdir -p /odoo/{config,tmp,log,server,odoo-custom-addons}

echo "Création de l'utilisateur système pour Odoo..."
sudo useradd -m -d /odoo/users -U -r -s /bin/bash odoo

echo "Changement de propriétaire des répertoires..."
sudo chown -R odoo:odoo /odoo

echo "Création de l'utilisateur PostgreSQL 'odoo' avec privilèges super-utilisateur..."
sudo su - postgres -c "createuser -s odoo"

echo "Téléchargement et installation de wkhtmltox..."
sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb
sudo apt install -y ./wkhtmltox_0.12.6-1.focal_amd64.deb

echo "Clonage du code source d'Odoo 14 depuis GitHub..."
sudo -u odoo git clone https://www.github.com/odoo/odoo --depth 1 --branch 14.0 /odoo/server

echo "Installation des dépendances Python pour Odoo..."
sudo -u odoo pip3 install -r /odoo/server/requirements.txt

echo "Configuration du fichier de service Odoo..."
cat <<EOL | sudo tee /etc/systemd/system/odoo.service
[Unit]
Description=Odoo14
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/odoo/server/odoo-bin -c /odoo/config/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOL

echo "Création du fichier de configuration Odoo..."
cat <<EOL | sudo tee /odoo/config/odoo.conf
[options]
addons_path = /odoo/server/addons,/odoo/server/odoo/addons,/odoo/odoo-custom-addons
admin_passwd = Admin@ups2021
db_host = False
db_port = False
db_user = odoo
db_password = False
logfile = /odoo/log/odoo.log
http_port = 8069
EOL

sudo chown odoo:odoo /odoo/config/odoo.conf

echo "Activation et démarrage du service Odoo..."
sudo systemctl daemon-reload
sudo systemctl enable odoo.service
sudo systemctl start odoo.service

echo "Installation terminée. Accédez à Odoo via : http://localhost:8069"
