FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    openjdk11 \
    openssh \
    bash \
    wget \
    curl \
    vim \
    net-tools \
    iputils \
    sudo \
    python3 \
    py3-pip \
    libc6-compat \
    procps \
    coreutils

# Set Java home
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV PATH=$PATH:$JAVA_HOME/bin

# Create hadoop, spark, and hive users
RUN adduser -D -s /bin/bash hadoop && \
    echo "hadoop:hadoop" | chpasswd && \
    addgroup hadoop wheel && \
    adduser -D -s /bin/bash spark && \
    echo "spark:spark" | chpasswd && \
    addgroup spark wheel && \
    adduser -D -s /bin/bash hive && \
    echo "hive:hive" | chpasswd && \
    addgroup hive wheel && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Setup SSH for passwordless login
RUN mkdir -p /home/hadoop/.ssh && \
    ssh-keygen -t rsa -P '' -f /home/hadoop/.ssh/id_rsa && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chmod 0600 /home/hadoop/.ssh/authorized_keys && \
    chown -R hadoop:hadoop /home/hadoop/.ssh

# SSH configuration
RUN ssh-keygen -A && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Download and install Hadoop 3.4.2
ENV HADOOP_VERSION=3.4.2
ENV HADOOP_HOME=/opt/hadoop
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz && \
    chown -R hadoop:hadoop ${HADOOP_HOME}

# Download and install Spark 4.0.1
ENV SPARK_VERSION=4.0.1
ENV SPARK_HOME=/opt/spark
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    chown -R hadoop:hadoop ${SPARK_HOME}

# Download and install Hive 4.1.0
ENV HIVE_VERSION=4.1.0
ENV HIVE_HOME=/opt/hive
RUN wget https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    mv apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME} && \
    rm apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    chown -R hadoop:hadoop ${HIVE_HOME}

# Remove conflicting guava jar from Hive (fixes compatibility issues)
RUN rm -f ${HIVE_HOME}/lib/guava-*.jar && \
    cp ${HADOOP_HOME}/share/hadoop/common/lib/guava-*.jar ${HIVE_HOME}/lib/ || true

# Set environment variables
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${HIVE_HOME}/bin
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV YARN_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV HDFS_NAMENODE_USER=hadoop
ENV HDFS_DATANODE_USER=hadoop
ENV HDFS_SECONDARYNAMENODE_USER=hadoop
ENV YARN_RESOURCEMANAGER_USER=hadoop
ENV YARN_NODEMANAGER_USER=hadoop

# Fix for Alpine's musl libc
ENV LD_LIBRARY_PATH=/lib:/usr/lib:$LD_LIBRARY_PATH

# # Final cleanup
# RUN rm -rf /var/cache/apk/* && \
#     rm -rf /tmp/*

WORKDIR /home/hadoop

# Expose ports
# HDFS ports
EXPOSE 9870 9000 9864 9866 9867
# YARN ports
EXPOSE 8088 8042 8030 8031 8032 8033
# Spark ports
EXPOSE 8080 7077 4040 18080
# Hive ports
EXPOSE 10000 10002 9083

USER hadoop

CMD ["/bin/bash"]