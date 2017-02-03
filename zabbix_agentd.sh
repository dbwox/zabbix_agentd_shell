#!/bin/bash

#进入源码目录
cd /usr/local/src

#下载zabbix源码
#wget https://nchc.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.2.3/zabbix-3.2.3.tar.gz
wget http://172.16.8.95/zabbix-3.2.3.tar.gz

#添加zabbix用户
groupadd zabbix -g 201
useradd -g zabbix -u 201 -m zabbix -s /sbin/nologin

#解压zabbix-3.2.3.tar.gz
tar zxvf zabbix-3.2.3.tar.gz

#进入zabbix_agents 目录
cd zabbix-3.2.3

#编译和安装zabbix agent
./configure --prefix=/usr/local/zabbix --enable-agent
make install

#修改配置/usr/local/zabbix/etc/zabbix_agentd.conf :Server  :ServerActive  :Hostname
sed -i 's/Server=127.0.0.1/Server=172.16.8.95/g' /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive=172.16.8.95/g' /usr/local/zabbix/etc/zabbix_agentd.conf
hostname=`hostname`
sed -i "s/Hostname\=/Hostname=${hostname}/g" /usr/local/zabbix/etc/zabbix_agentd.conf
#wget http://127.0.0.1/zabbix-3.2.3.tar.gz
#sed -i 's/http\:\/\/172.16.8.95/http\:\/\/127.0.0.1/g' ~/zabbix_agentd.sh
#vim /usr/local/zabbix/etc/zabbix_agentd.conf
#sed -i "s/Hostname\=/Hostname=${hostname}/g" ~/a
#sed -i '15,20d' /etc/sysconfig/iptables

#返回目录/usr/local/src
cd /usr/local/src

#杀死所有zabbix_agentd进程，防止拷贝时提示占用
killall zabbix_agentd
cp zabbix-3.2.3/misc/init.d/tru64/zabbix_agentd /etc/init.d/

#授权可执行
chmod +x /etc/init.d/zabbix_agentd

ln -s /usr/local/zabbix/sbin/* /usr/local/sbin/
ln -s /usr/local/zabbix/bin/* /usr/local/bin/

#更改属主
chown -R zabbix:zabbix /usr/local/zabbix/*

#添加开机启动
sed -i -e '/# Zabbix/a\#chkconfig: 2345 10 90\n#description: zabbix agent' /etc/rc.d/init.d/zabbix_agentd
chkconfig --add zabbix_agentd
chkconfig zabbix_agentd on
service zabbix_agentd restart

#查看zabbix_agentd进程
ps -ef | grep zabbix_agentd

#在系统服务中声明端口号及应用名
sed -i '$a\zabbix-agent 10050/tcp #ZabbixAgent\nzabbix-agent 10050/udp #ZabbixAgent\nzabbix-trapper 10051/tcp #ZabbixTrapper\nzabbix-trapper 10051/udp #ZabbixTrapper' /etc/services

#iptables中添加10050 10051端口并重启
sed -i -e '/-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT/a-A INPUT -m state --state NEW -m tcp -p tcp --dport 10050 -j ACCEPT\n-A INPUT -m state --state NEW -m tcp -p tcp --dport 10051 -j ACCEPT' /etc/sysconfig/iptables
service iptables restart

#/usr/local/zabbix/bin/zabbix_get -s 172.16.8.95 -p 10050 -k "system.uptime"