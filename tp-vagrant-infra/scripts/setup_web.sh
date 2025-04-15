#!/bin/bash

echo "VM client – tests en cours..."
echo "Configuration du serveur web (Apache)..."
# Mettre à jour les paquets
sudo apt-get update

# Installer Apache
sudo apt-get install -y apache2

# Créer une page HTML personnalisée
echo "<h1>Hello from $(hostname) </h1>" | sudo tee /var/www/html/index.html

# Activer Apache
sudo systemctl enable apache2
sudo systemctl start apache2


echo "Test complet terminé."
echo "VM client – tests terminés."