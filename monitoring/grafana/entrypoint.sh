#!/bin/bash

# Ensure the Grafana data directory exists
mkdir -p /var/lib/grafana

# Start Grafana
/usr/share/grafana/bin/grafana-server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini
