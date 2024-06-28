#!/bin/bash

echo "Installing connector plugins"
echo "Downloading MongoDB Driver"
confluent-hub install --no-prompt confluentinc/kafka-connect-hdfs:10.2.6
confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.11.2
echo "Launching Kafka Connect worker"
exec /etc/confluent/docker/run
