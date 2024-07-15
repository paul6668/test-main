#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Download and install JDK
#wget --no-check-certificate --no-cookies \
#    --header "Cookie: oraclelicense=accept-securebackup-cookie" \
#    http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz

tar -xzf MirrorShip-EE-3.2.8/file/openjdk-8u322-b06-linux-x64.tar.gz -C /usr/local
ln -s /usr/local/java-se-8u322-b06 /usr/local/java-se
JAVA_HOME=/usr/local/java-se

# Set JAVA_HOME
echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile
source /etc/profile
java -version

# Adjust kernel parameters
echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
sysctl -p

# Transparent HugePages Configuration
echo madvise | tee /sys/kernel/mm/transparent_hugepage/enabled
echo madvise | tee /sys/kernel/mm/transparent_hugepage/defrag

cat >> /etc/rc.d/rc.local << EOF
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo madvise > /sys/kernel/mm/transparent_hugepage/defrag
fi
EOF

chmod +x /etc/rc.d/rc.local

# Disable swap space (manual step required)
# Please manually remove swap entries from /etc/fstab
echo "Please remove swap entries from /etc/fstab manually."

# Set swappiness
echo "vm.swappiness=0" >> /etc/sysctl.conf
sysctl -p

# Set I/O scheduler
echo "echo kyber | tee /sys/block/\${disk}/queue/scheduler" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

# Disable SELinux
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
sed -i 's/SELINUXTYPE/#SELINUXTYPE/' /etc/selinux/config

# Stop and disable firewall
systemctl stop firewalld.service
systemctl disable firewalld.service

# Set locale
echo "export LANG=en_US.UTF8" >> /etc/profile
source /etc/profile

# Set timezone
cp -f /usr/share/zoneinfo/Asia/Macau /etc/localtime
hwclock

# Set resource limits
cat >> /etc/security/limits.conf << EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 655350
* hard nofile 655350
* soft stack unlimited
* hard stack unlimited
* hard memlock unlimited
* soft memlock unlimited
EOF

cat >> /etc/security/limits.d/20-nproc.conf << EOF
*          soft    nproc     65535
root       soft    nproc     65535
EOF

# Set TCP parameters
echo "net.ipv4.tcp_abort_on_overflow=1" >> /etc/sysctl.conf
sysctl -p

# Set connection backlog
echo "net.core.somaxconn=1024" >> /etc/sysctl.conf
sysctl -p

# Set max map count
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p

# Set kernel parameters
echo 120000 > /proc/sys/kernel/threads-max
echo 200000 > /proc/sys/kernel/pid_max
