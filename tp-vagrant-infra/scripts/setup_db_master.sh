#!/bin/bash

echo "Configuration de la base de données MASTER..."

# Mettre à jour les paquets
sudo apt-get update

# Installer MySQL Server sans prompt
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

# Activer MySQL
sudo systemctl enable mysql
sudo systemctl start mysql

# Modifier la config MySQL pour la réplication
sudo sed -i '/\[mysqld\]/a \
server-id = 1\n\
log_bin = /var/log/mysql/mysql-bin.log\n\
binlog_do_db = replicated_db\n\
bind-address = 0.0.0.0' /etc/mysql/mysql.conf.d/mysqld.cnf

# Redémarrer MySQL pour appliquer la conf
sudo systemctl restart mysql

# Créer la base et l'utilisateur pour la réplication
sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS replicated_db;
CREATE USER 'replicator'@'%' IDENTIFIED WITH mysql_native_password BY 'replica_pass';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
EOF

