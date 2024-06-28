#!/usr/bin/env bash

# Set Spark environment variables
export SPARK_MASTER_HOST=master
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_CONF_DIR=/etc/hadoop/conf
export SPARK_HOME=/opt/spark
export SPARK_CONF_DIR=$SPARK_HOME/conf
export SPARK_WORKER_MEMORY=4g
export SPARK_WORKER_CORES=2
export SPARK_DRIVER_MEMORY=2g
export SPARK_EXECUTOR_MEMORY=4g
export SPARK_EXECUTOR_CORES=2
