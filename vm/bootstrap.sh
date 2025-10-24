# Update Packages
apt update
# Upgrade Packages
apt upgrade

# 
apt install openjdk-8-jre-headless ssh pdsh wget

ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

wget https://mirrors.estointernet.in/apache/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz
wget https://ftp.kddi-research.jp/infosystems/apache/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz
wget https://mirrors.estointernet.in/apache/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz
wget https://dlcdn.apache.org/hbase/2.4.6/hbase-2.4.6-bin.tar.gz

tar -C /opt -xzvf hadoop-3.3.1.tar.gz
tar -C /opt -xzvf apache-hive-3.1.2-bin.tar.gz
tar -C /opt -xzvf hbase-2.4.6-bin.tar.gz
tar -C /opt -xzvf spark-3.1.2-bin-hadoop3.2.tgz

cd /opt
mv hadoop-3.3.1 hadoop
mv apache-hive-3.1.2-bin hive
mv spark-3.1.2-bin-hadoop3.2 spark
mv hbase-2.4.6-bin hbase

cd

#vi ~/.bashrc
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/' >> ~/.bashrc
echo 'export HADOOP_HOME=/opt/hadoop' >> ~/.bashrc
echo 'export HADOOP_INSTALL=$HADOOP_HOME' >> ~/.bashrc
echo 'export HADOOP_MAPRED_HOME=$HADOOP_HOME' >> ~/.bashrc
echo 'export HADOOP_COMMON_HOME=$HADOOP_HOME' >> ~/.bashrc
echo 'export HADOOP_HDFS_HOME=$HADOOP_HOME' >> ~/.bashrc
echo 'export YARN_HOME=$HADOOP_HOME' >> ~/.bashrc
echo 'export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native' >> ~/.bashrc
echo 'export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export HIVE_HOME=/opt/hive' >> ~/.bashrc
echo 'export PATH=$PATH:$HIVE_HOME/bin' >> ~/.bashrc
echo 'export HBASE_HOME=/opt/hbase' >> ~/.bashrc
echo 'export PATH=$PATH:$HBASE_HOME/bin' >> ~/.bashrc
echo 'export SPARK_HOME=/opt/spark' >> ~/.bashrc
echo 'export PATH=$PATH:$SPARK_HOME/bin' >> ~/.bashrc
echo 'export PYSPARK_DRIVER_PYTHON="jupyter"' >> ~/.bashrc
echo 'export PYSPARK_DRIVER_PYTHON_OPTS="notebook"' >> ~/.bashrc
echo 'export PYSPARK_PYTHON=python3' >> ~/.bashrc

source ~/.bashrc

sudo mkdir -p /app/hadoop/tmp
mkdir -p ~/hdfs/namenode
mkdir ~/hdfs/datanode

sudo chown -R $USER:$USER /app
chmod a+rw -R /app


#vi /opt/hadoop/etc/hadoop/core-site.xml
sed '/^</configuration>=.*/i 
	<property>
		<name>hadoop.tmp.dir</name>
		<value>/app/hadoop/tmp</value>
		<description>Parent directory for other temporary directories.</description>
    </property>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>' /opt/hadoop/etc/hadoop/core-site.xml

#vi hadoop-env.sh
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/' >> /opt/hadoop/etc/hadoop/hadoop-env.sh

#vi /opt/hadoop/etc/hadoop/hdfs-site.xml
sed '/^</configuration>=.*/i 
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
	<property>
		<name>dfs.name.dir</name>
		<value>file:///home/$USER/hdfs/namenode</value>
    </property>
    <property>
		<name>dfs.data.dir</name>
		<value>file:///home/$USER/hdfs/datanode</value>
    </property>' /opt/hadoop/etc/hadoop/hdfs-site.xml

#vi /opt/hadoop/etc/hadoop/mapred-site.xml
sed '/^</configuration>=.*/i 
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>' /opt/hadoop/etc/hadoop/mapred-site.xml

#vi /opt/hadoop/etc/hadoop/yarn-site.xml
sed '/^</configuration>=.*/i 
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>' /opt/hadoop/etc/hadoop/yarn-site.xml


# start hadoop
hdfs namenode -format

start-all.sh

# after starting hadoop
hdfs dfs -mkdir -p /tmp
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod -R a+rw /tmp
hdfs dfs -chmod -R a+rw /user/hive

# Set MySQL Pass
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

# Install MySQL
apt-get install -y mysql-server

mysql -uroot -proot -e "CREATE DATABASE metastore;"
mysql -uroot -proot -e "CREATE USER 'hive'@'%' IDENTIFIED BY 'hive';"
mysql -uroot -proot -e "GRANT ALL ON metastore.* TO 'hive'@'%' WITH GRANT OPTION;"

sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf 
systemctl restart mysql.service

wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.26.tar.gz
tar -xzvf mysql-connector-java-8.0.26.tar.gz
cp ./mysql-connect-java-8.0.26/mysql-connector-java-8.0.26.jar /opt/hive/lib/

#vi /opt/hive/conf/hive-site.xml
sed '/^</configuration>=.*/i 
<property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://localhost:3306/metastore?createDatabaseIfNotExist=true&amp;useLegacyDatetimeCode=false&amp;serverTimezone=UTC</value>
        <description>metadata is stored in a MySQL server</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.jdbc.Driver</value>
        <description>MySQL JDBC driver class</description>
     </property>
     <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
        <description>user name for connecting to mysql server</description>
     </property>
     <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive</value>
        <description>password for connecting to mysql server</description>
     </property>' /opt/hive/conf/hive-site.xml


schematool -dbType mysql -initSchema
hive --service metastore


echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/' >> /opt/hbase/conf/hbase-env.sh
echo 'export HBASE_REGIONSERVERS=${HBASE_HOME}/conf/regionservers' >> /opt/hbase/conf/hbase-env.sh
echo 'export HBASE_MANAGES_ZK=true' >> /opt/hbase/conf/hbase-env.sh

#vi /opt/hbase/conf/hbase-site.xml 
sed '/^</configuration>=.*/i 
<property>
    <name>hbase.rootdir</name>
    <value>hdfs://localhost:54310/hbase</value>
  </property>

  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>

  <property>
    <name>hbase.zookeeper.property.clientPort</name>
    <value>2222</value>
  </property>

  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>/home/hduser/zookeeper</value>
  </property> ' /opt/hbase/conf/hbase-site.xml 

start-hbase.sh

cp $HADOOP_HOME/etc/hadoop/core-site.xml /opt/spark/conf/
cp $HADOOP_HOME/etc/hadoop/hdfs-site.xml /opt/spark/conf/

#vi /opt/spark/conf/hive-site.xml
sed '/^</configuration>=.*/i 
        <property>
                <name>hive.metastore.uris</name>
                <value>thrift://localhost:9083</value>
        </property>
        <property>
                <name>spark.sql.warehouse.dir</name>
                <value>hdfs://localhost:9000/user/hive/warehouse</value>
        </property>' /opt/spark/conf/hive-site.xml
		
pip3 install pyspark