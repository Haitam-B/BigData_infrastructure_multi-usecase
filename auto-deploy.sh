#!/bin/bash

# Update and install necessary dependencies
apt-get update && apt-get install -y \
    curl \
    wget \
    software-properties-common \
    docker.io \
    docker-compose

# Activate and start Docker services
systemctl enable docker
systemctl start docker

# Add current user to docker users groupe
usermod -aG docker $USER

# Create Cluster bridge docker network
docker network create --driver bridge clusterbridge

# docker-compose.yml repository
COMPOSE_DIR="./"

# Services availability check function
wait_for_it() {
    local serviceport=$1
    local service=${serviceport%%:*}
    local port=${serviceport#*:}
    local retry_seconds=5
    local max_try=100
    let i=1

    nc -z $service $port
    result=$?

    until [ $result -eq 0 ]; do
      echo "[$i/$max_try] check for ${service}:${port}..."
      echo "[$i/$max_try] ${service}:${port} is not available yet"
      if (( $i == $max_try )); then
        echo "[$i/$max_try] ${service}:${port} is still not available; giving up after ${max_try} tries. :/"
        exit 1
      fi

      echo "[$i/$max_try] try in ${retry_seconds}s once again ..."
      let "i++"
      sleep $retry_seconds

      nc -z $service $port
      result=$?
    done
    echo "[$i/$max_try] $service:${port} is available."
}

# Lanch docker-compose
cd $COMPOSE_DIR
docker-compose up -d

# Verify services availability
SERVICES=("spark-master:8080" "hdfs-namenode:9870" "resources-manager:8088" "hive-server:10000" "prometheus:9090" "grafana:3000")
for service in "${SERVICES[@]}"; do
  wait_for_it $service
done

echo "Deploiment successfuly completed!"
echo "Spark master UI at      : spark-master:8080"
echo "HDFS namenode UI at     : hdfs-namenode:9870"
echo "Resources manager UI at : resources-manager:8088"
echo "Prometheus UI at        : spark-master:9090"
echo "Grafana UI at           : spark-master:3000"