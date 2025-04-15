#!/bin/bash

echo "Configuration du Load Balancer (NGINX)..."

# Mettre à jour les paquets
sudo apt-get update

# Installer nginx
sudo apt-get install -y nginx

# Supprimer la configuration par défaut
sudo rm -f /etc/nginx/sites-enabled/default

# Créer un fichier de configuration pour le load balancer
cat <<EOF | sudo tee /etc/nginx/sites-available/load_balancer
upstream backend {
    server 192.168.56.11;
    server 192.168.56.12;
}

server {
    listen 80;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Activer la nouvelle configuration
sudo ln -s /etc/nginx/sites-available/load_balancer /etc/nginx/sites-enabled/load_balancer

# Redémarrer nginx
sudo systemctl restart nginx

echo "Load Balancer prêt sur http://192.168.56.10"
echo "Configuration du Load Balancer (NGINX) terminée."
echo "Configuration de l'IP du Load Balancer (NGINX) terminée."
