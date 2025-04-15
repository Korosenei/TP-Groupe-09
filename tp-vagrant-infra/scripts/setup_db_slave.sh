#!/bin/bash

echo "Configuration de la base de données SLAVE..."


# Mettre à jour les paquets
sudo apt-get update

# Installer MySQL
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

# Activer MySQL
sudo systemctl enable mysql
sudo systemctl start mysql

# Modifier la config MySQL pour la réplication
sudo sed -i '/\[mysqld\]/a \
server-id = 2\n\
relay-log = /var/log/mysql/mysql-relay-bin.log\n\
bind-address = 0.0.0.0' /etc/mysql/mysql.conf.d/mysqld.cnf

# Redémarrer MySQL
sudo systemctl restart mysql

# Configurer la réplication
sudo mysql -u root <<EOF
STOP SLAVE;

CHANGE MASTER TO
  MASTER_HOST='192.168.56.13',
  MASTER_USER='replicator',
  MASTER_PASSWORD='replica_pass',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=959;

START SLAVE;
EOF

echo "MySQL Slave connecté au Master."
