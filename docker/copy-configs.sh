#!/bin/bash

# Start a temporary container
CONTAINER_ID=$(podman run -d hadoop-cluster:3.4.2 tail -f /dev/null)

# Copy configuration files
podman cp configs/core-site.xml $CONTAINER_ID:/opt/hadoop/etc/hadoop/
podman cp configs/hdfs-site.xml $CONTAINER_ID:/opt/hadoop/etc/hadoop/
podman cp configs/mapred-site.xml $CONTAINER_ID:/opt/hadoop/etc/hadoop/
podman cp configs/yarn-site.xml $CONTAINER_ID:/opt/hadoop/etc/hadoop/
podman cp configs/workers $CONTAINER_ID:/opt/hadoop/etc/hadoop/
podman cp configs/hive-site.xml $CONTAINER_ID:/opt/hive/conf/
podman cp configs/spark-defaults.conf $CONTAINER_ID:/opt/spark/conf/

# Append hadoop-env additions
podman exec $CONTAINER_ID bash -c "cat /tmp/hadoop-env-additions.sh >> /opt/hadoop/etc/hadoop/hadoop-env.sh"

# Commit the changes
podman commit $CONTAINER_ID hadoop-cluster:3.4.2

# Clean up
podman stop $CONTAINER_ID
podman rm $CONTAINER_ID

echo "Configuration copied and image updated"