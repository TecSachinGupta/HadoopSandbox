# Multi-Node Hadoop 3.4.2 Cluster with Spark 4.0.1 and Hive 4.1.0 using Podman (Alpine + Java 11)

This guide will help you set up a complete modern Hadoop ecosystem with Hadoop 3.4.2, Spark 4.0.1 and Hive 4.1.0 using Podman with Alpine Linux and Java 11. Each framework runs under its own dedicated user for better security and isolation.

## Prerequisites

- Podman and podman-compose installed
- At least 6GB RAM available (Alpine is more lightweight)
- 15GB disk space (Alpine base image is ~100MB vs Ubuntu's ~600MB)

## Cluster Components

- **Hadoop 3.4.2**: Latest stable HDFS and YARN with bug fixes
- **Spark 4.0.1**: Latest Spark with enhanced performance and new features
- **Hive 4.1.0**: Latest Hive with improved query optimization
- **Java 11**: Modern JVM with better performance
- **Alpine Linux**: Lightweight base image

### Architecture
- **NameNode**: HDFS master, Hive Metastore, HiveServer2, Spark History Server
- **2x DataNodes**: HDFS data storage
- **ResourceManager**: YARN master
- **2x NodeManagers**: YARN workers

### User Separation for Security
- **hadoop** user: Runs HDFS (NameNode, DataNodes) and YARN (ResourceManager, NodeManagers)
- **spark** user: Runs Spark services (History Server) and Spark jobs
- **hive** user: Runs Hive services (Metastore, HiveServer2) and Hive queries
- All users have SSH access to each other and can submit jobs to YARN
- Shared directories configured for inter-framework communication

## Setup Instructions

### Step 1: Create Project Directory

```bash
mkdir hadoop-cluster
cd hadoop-cluster
```

### Step 2: Create Configuration Files

Save the configuration script and run it:

```bash
# Save setup-configs.sh and make it executable
chmod +x setup-configs.sh
./setup-configs.sh
```

### Step 3: Build the Hadoop Image

```bash
# Save the Dockerfile
podman build -t hadoop-cluster:3.4.0 .
```

This will take 10-15 minutes as it downloads Hadoop, Spark, and Hive. The Alpine base image is much smaller (~100MB) compared to Ubuntu (~600MB), resulting in a faster build and smaller final image.

### Step 4: Copy Configuration Files into Image

Create a setup script to copy configs:

```bash
cat > copy-configs.sh << 'EOF'
#!/bin/bash

# Start a temporary container
CONTAINER_ID=$(podman run -d hadoop-cluster:3.4.0 tail -f /dev/null)

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
podman commit $CONTAINER_ID hadoop-cluster:3.4.0

# Clean up
podman stop $CONTAINER_ID
podman rm $CONTAINER_ID

echo "Configuration copied and image updated"
EOF

chmod +x copy-configs.sh
./copy-configs.sh
```

### Step 5: Start the Cluster

```bash
podman-compose up -d
```

Wait 1-2 minutes for all services to start.

### Step 6: Verify Cluster Status

Check if all containers are running:

```bash
podman ps
```

### Step 7: Initialize Hive

```bash
# Create HDFS directories for Hive (as hadoop user)
podman exec -it -u hadoop namenode bash -c "
  hdfs dfs -mkdir -p /user/hive/warehouse
  hdfs dfs -mkdir -p /tmp
  hdfs dfs -mkdir -p /user/spark
  hdfs dfs -chown -R hive:hadoop /user/hive
  hdfs dfs -chown spark:hadoop /user/spark
  hdfs dfs -chmod g+w /user/hive/warehouse
  hdfs dfs -chmod g+w /tmp
"

# Initialize Hive schema (as hive user)
podman exec -it -u hive namenode bash -c "
  cd /opt/hive
  bin/schematool -initSchema -dbType derby
"

# Start Hive Metastore (as hive user, in background)
podman exec -d -u hive namenode bash -c "
  cd /opt/hive
  nohup bin/hive --service metastore > /tmp/metastore.log 2>&1 &
"

# Start HiveServer2 (as hive user, in background)
podman exec -d -u hive namenode bash -c "
  cd /opt/hive
  nohup bin/hiveserver2 > /tmp/hiveserver2.log 2>&1 &
"
```

### Step 8: Initialize Spark History Server

```bash
# Create HDFS directory for Spark logs (as hadoop user)
podman exec -it -u hadoop namenode bash -c "
  hdfs dfs -mkdir -p /spark-logs
  hdfs dfs -chown spark:hadoop /spark-logs
  hdfs dfs -chmod 1777 /spark-logs
"

# Start Spark History Server (as spark user)
podman exec -d -u spark namenode bash -c "
  /opt/spark/sbin/start-history-server.sh
"
```

## Access Web UIs

- **NameNode UI**: http://localhost:9870
- **ResourceManager UI**: http://localhost:8088
- **DataNode1 UI**: http://localhost:9864
- **DataNode2 UI**: http://localhost:9865
- **NodeManager1 UI**: http://localhost:8042
- **NodeManager2 UI**: http://localhost:8043
- **Spark History Server**: http://localhost:18080

## Testing the Cluster

### Test HDFS

```bash
# Test as hadoop user
podman exec -it -u hadoop namenode bash

# Create a test directory
hdfs dfs -mkdir -p /user/hadoop/test

# Create a test file
echo "Hello Hadoop" > test.txt
hdfs dfs -put test.txt /user/hadoop/test/

# Verify
hdfs dfs -ls /user/hadoop/test/
hdfs dfs -cat /user/hadoop/test/test.txt
exit
```

### Test MapReduce

```bash
# Test as hadoop user
podman exec -it -u hadoop namenode bash

# Run the Pi estimation example
hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.2.jar pi 4 100
exit
```

### Test Spark

```bash
# Test as spark user
podman exec -it -u spark namenode bash

# Run Spark Pi example (note: Spark 4.0.1 uses Scala 2.13)
spark-submit --class org.apache.spark.examples.SparkPi \
  --master yarn \
  --deploy-mode client \
  /opt/spark/examples/jars/spark-examples_2.13-4.0.1.jar 100
exit
```

### Test Hive

```bash
# Test as hive user
podman exec -it -u hive namenode bash

# Connect to Hive via beeline
beeline -u jdbc:hive2://localhost:10000

# Inside beeline, run:
CREATE TABLE test_table (id INT, name STRING);
INSERT INTO test_table VALUES (1, 'John'), (2, 'Jane');
SELECT * FROM test_table;
!quit
exit
```

### Test Spark with Hive

```bash
# Test as spark user
podman exec -it -u spark namenode bash

# Start Spark shell with Hive support
spark-shell --master yarn

# In Spark shell:
spark.sql("SHOW DATABASES").show()
spark.sql("SELECT * FROM test_table").show()
exit
```

## Stopping the Cluster

```bash
podman-compose down
```

## Removing Everything

```bash
podman-compose down -v
podman rmi hadoop-cluster:3.4.0
```

## Troubleshooting

### Check logs for a specific service:

```bash
podman logs namenode
podman logs datanode1
podman logs resourcemanager
```

### If NameNode fails to start:

```bash
podman exec -it namenode bash
hdfs namenode -format -force
```

### If Hive connection fails:

Check if metastore is running:
```bash
podman exec -it -u hive namenode bash
ps aux | grep metastore
```

Check logs:
```bash
podman exec -it namenode cat /tmp/metastore.log
podman exec -it namenode cat /tmp/hiveserver2.log
```

### Increase memory for YARN:

Edit `configs/yarn-site.xml` and increase memory values, then rebuild the image.

## Performance Tuning

For production use, consider:

1. Increasing replication factor in `hdfs-site.xml`
2. Adjusting YARN memory settings based on your host resources
3. Configuring Spark executor memory and cores
4. Using external PostgreSQL/MySQL for Hive metastore instead of Derby
5. Adding more DataNodes and NodeManagers

## Additional Notes

- **User Accounts**:
  - `hadoop` user (password: `hadoop`) - Runs HDFS and YARN
  - `spark` user (password: `spark`) - Runs Spark services
  - `hive` user (password: `hive`) - Runs Hive services
- All data is persisted in Podman volumes
- The cluster uses a bridge network for inter-container communication
- SSH is configured for passwordless authentication between all users
- **Alpine Benefits**: Smaller image size (~1.5GB total vs ~3GB with Ubuntu), faster startup times, reduced memory footprint
- Alpine uses `musl libc` instead of `glibc` - this is handled automatically in the Dockerfile
- **Java 11**: Provides better performance, improved garbage collection (G1GC), and modern JVM features. All components fully support Java 11
- **Latest Versions**: 
  - Hadoop 3.4.2 includes critical bug fixes and security patches over 3.4.0
  - Spark 4.0.1 includes Scala 2.13, improved Catalyst optimizer, better Kubernetes support
  - Hive 4.1.0 includes ACID improvements, better Iceberg integration, enhanced security
  - All versions are production-ready and fully compatible
- **Security Benefits**: Separate users provide:
  - Process isolation between frameworks
  - Better audit trails (logs show which user ran what)
  - Reduced privilege escalation risk
  - Easier permission management on HDFS