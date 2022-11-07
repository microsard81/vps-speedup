#!/bin/bash
#

cat << EOF > /bin/updateall
#!/bin/bash
#

apt update ; apt -y dist-upgrade ; apt -y autoremove

EOF

chmod +x /bin/updateall

echo "------------------------------------------------------------------------------------------------"
echo "================================================================================================"
echo " "
echo "Please, specify the device details"
echo " "
echo "================================================================================================"
read -p 'SU Serial Number: ' sn
read -p 'VPS hostname: ' host
read -p 'VPS Zabbix hostname: ' zabbix

apt install -y zabbix-agent molly-guard

cat << EOF > /etc/zabbix/zabbix_agentd.conf
PidFile=/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix-agent/zabbix_agentd.log
LogFileSize=1
AllowRoot=1
Server=82.191.45.246
ServerActive=82.191.45.246
Hostname=$zabbix
UserParameter=devicetype,AlwaysOnSpeedUp-VPS
UserParameter=serialnumber,echo "VPS_$sn"
HostMetadataItem=devicetype
Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf
EOF

cat << EOF > /etc/motd


SUNDATA ALWAYS ON: $host


EOF

cat << EOF > /etc/zabbix/zabbix_agentd.conf.d/alwayson.conf
UserParameter=remote.status,gtstatus
EOF

cat << EOF > /bin/gtstatus
#!/bin/bash
#


p=""

if [[ \$(netstat -anlp 2>/dev/null | grep 65001 | grep ESTA | awk '{print $5}' | awk -F'[:]' '{print $1}') ]]; then
    p="connected"
else
    p="not connected"
fi

echo \$p
EOF

chmod +x /bin/gtstatus

echo "================================================================================================"
echo "Customization complete. Please reboot the device"
echo " "
rm -- "$0"
