#!/bin/bash

export CORE_CONF_fs_defaultFS=${CORE_CONF_fs_defaultFS:-hdfs://master:8020}

function addProperty() {
  local path=$1
  local name=$2
  local value=$3

  local entry="<property><name>$name</name><value>${value}</value></property>"
  local escapedEntry=$(echo $entry | sed 's/\//\\\//g')
  sed -i "/<\/configuration>/ s/.*/${escapedEntry}\n&/" $path
}

function configure() {
    local path=$1
    local module=$2
    local envPrefix=$3

    local var
    local value

    echo "Configuring $module"
    for c in `printenv | perl -sne 'print "$1 " if m/^${envPrefix}_(.+?)=.*/' -- -envPrefix=$envPrefix`; do
        name=`echo ${c} | perl -pe 's/___/-/g; s/__/@/g; s/_/./g; s/@/_/g;'`
        var="${envPrefix}_${c}"
        value=${!var}
        echo " - Setting $name=$value"
        addProperty $path $name "$value"
    done
}

configure /etc/hadoop/core-site.xml core CORE_CONF
configure /etc/hadoop/hdfs-site.xml hdfs HDFS_CONF
configure /etc/hadoop/yarn-site.xml yarn YARN_CONF
configure /etc/hadoop/httpfs-site.xml httpfs HTTPFS_CONF
configure /etc/hadoop/kms-site.xml kms KMS_CONF
configure /etc/hadoop/mapred-site.xml mapred MAPRED_CONF
configure /opt/hive/conf/hive-site.xml hive HIVE_SITE_CONF

export FS_DEFAULT_NAME="hdfs://master:9000"
export YARN_RESOURCE_MANAGER_ADDRESS="master:8050"

# Function to wait for a service to be ready
wait_for_it() {
    local serviceport=$1
    local service=${serviceport%%:*}
    local port=${serviceport#*:}
    local retry_seconds=5
    local max_try=100
    local i=1

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
        ((i++))
        sleep $retry_seconds

        nc -z $service $port
        result=$?
    done
    echo "[$i/$max_try] $service:${port} is available."
}

# Wait for dependencies to be ready
for service in ${SERVICE_PRECONDITION[@]}; do
    wait_for_it ${service}
done

# Start Hadoop services
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

# Start the NodeManager
$HADOOP_HOME/sbin/yarn-daemon.sh start nodemanager

# Start the Hive service
if [ "$SERVICE_ROLE" == "metastore" ]; then
    $HIVE_HOME/bin/hive --service metastore &
elif [ "$SERVICE_ROLE" == "hiveserver2" ]; then
    $HIVE_HOME/bin/hive --service hiveserver2 &
fi

# Keep the container running
tail -f /dev/null
