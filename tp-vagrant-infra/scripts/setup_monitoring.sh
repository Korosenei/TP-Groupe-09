#!/bin/bash

#!/bin/bash
set -euo pipefail

# INSTALLATION DE PROMETHEUS + EXPORTERS
echo "Installation de Prometheus..."

# Créer un utilisateur dédié
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Télécharger et installer Prometheus
PROM_VERSION="2.47.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
sudo cp prometheus-${PROM_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-${PROM_VERSION}.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-${PROM_VERSION}.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-${PROM_VERSION}.linux-amd64/console_libraries /etc/prometheus

# Configuration Prometheus
cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['192.168.56.11:9100', '192.168.56.12:9100'] # web1, web2

  - job_name: 'mysql'
    static_configs:
      - targets: ['192.168.56.13:9104', '192.168.56.14:9104'] # db-master, db-slave
EOF

# Service systemd pour Prometheus
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Installer Node Exporter 
echo "Installation de Node Exporter..."
NODE_EXPORTER_VERSION="1.7.0"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-*.tar.gz
sudo cp node_exporter-*/node_exporter /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/node_exporter

cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# INSTALLATION DE GRAFANA
echo "Installation de Grafana..."
sudo apt-get install -y apt-transport-https software-properties-common
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana

# Configuration Grafana
sudo systemctl daemon-reload
sudo systemctl enable grafana-server

# CONFIGURATION DES DASHBOARDS
echo "Configuration des dashboards..."

# Attendre que Grafana soit démarré
sleep 10

# Importer le dashboard Node Exporter via API
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {
      "id": null,
      "uid": null,
      "title": "Node Metrics",
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0
    },
    "folderId": 0,
    "overwrite": false
  }' \
  http://admin:admin@localhost:3000/api/dashboards/db

# DÉMARRAGE DES SERVICES
echo "Démarrage des services..."
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus node_exporter grafana-server

# VÉRIFICATION
echo "Installation terminée !"
echo "Prometheus : http://192.168.56.15:9090"
echo "Grafana : http://192.168.56.15:3000 (admin/admin)"
echo "Node Exporter : http://192.168.56.15:9100/metrics"

