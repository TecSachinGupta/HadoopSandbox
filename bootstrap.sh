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

vi ~/.bashrc
export HADOOP_HOME=/opt/hadoop
export HADOOP_INSTALL=$HADOOP_HOME
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HIVE_HOME/bin
export HBASE_HOME=/opt/hbase
export PATH=$PATH:$HBASE_HOME/bin
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin

source ~/.bashrc

sudo mkdir -p /app/hadoop/tmp
mkdir -p ~/hdfs/namenode
mkdir ~/hdfs/datanode

sudo chown -R $USER:$USER /app
chmod a+rw -R /app


vi /opt/hadoop/etc/hadoop/core-site.xml
<configuration>
	<property>
		<name>hadoop.tmp.dir</name>
		<value>/app/hadoop/tmp</value>
		<description>Parent directory for other temporary directories.</description>
    </property>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>

vi hadoop-env.sh
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/


vi /opt/hadoop/etc/hadoop/hdfs-site.xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
	<property>
		<name>dfs.name.dir</name>
		<value>file:///home/YOUR_USER/hdfs/namenode</value>
    </property>
    <property>
		<name>dfs.data.dir</name>
		<value>file:///home/YOUR_USER/hdfs/datanode</value>
    </property>
</configuration>

vi /opt/hadoop/etc/hadoop/mapred-site.xml
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>

vi /opt/hadoop/etc/hadoop/yarn-site.xml
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>




# after starting hadoop
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod -R a+rw /user/hive
