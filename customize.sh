#!/bin/bash
#

cat << EOF > /bin/updateall
#!/bin/bash
#

apt update --fix-missing ; apt update ; apt -y dist-upgrade ; apt -y autoremove

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
read -p 'Backup folder name: ' bckfolder

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

debconf-set-selections <<< "postfix postfix/mailname string "`cat /etc/hostname`
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

apt install --assume-yes postfix mailutils mutt

echo "root:   vms@itcarmat.net" >> /etc/aliases ; newaliases ; systemctl restart postfix

mkdir /opt/backup

cat << EOF > /opt/backup/backup_check.sh
#!/bin/bash

# Specifica il percorso del file che vuoi monitorare
file_da_monitorare="/var/opt/openmptcprouter/openmptcprouter-backup.tar.gz"

# Specifica l'indirizzo email del destinatario
destinatario="confbackup@itcarmat.net"

# Specifica il nome cliente
cliente=\$1

# Specifica l'oggetto e il corpo del messaggio
oggetto="[\$cliente] - Nuovo backup di openmptcprouter"
messaggio="Il backup \$file_da_monitorare è stato modificato."

# Specifica il percorso del file di stato
file_di_stato="/opt/backup/state.txt"

# Ottieni la data di modifica attuale del file
data_modifica_attuale=\$(stat -c %y "\$file_da_monitorare")

# Inizializza la data di modifica precedente da file di stato, se presente
if [ -e "\$file_di_stato" ]; then
    data_modifica_precedente=\$(cat "\$file_di_stato")
else
    data_modifica_precedente=""
fi


# Confronta le date di modifica
if [ "\$data_modifica_attuale" != "\$data_modifica_precedente" ]; then
    # Modifica il nome dell'allegato
    allegato=\$cliente"_openmptcprouter-backup-"\$(date +"%Y%m%d%H%M")".tar.gz"
    cp \$file_da_monitorare /opt/backup/\$allegato

    # Invia una mail con l'allegato
    echo "\$messaggio" | mutt -s "\$oggetto" -a "/opt/backup/\$allegato" -e "set content_type=text/plain" -- "\$destinatario"

    # Avvisa dell'avvenuto invio della mail, in seguito alla modifica del file
    echo "Rilevata modifica al file del backup. Invio al sistema di gestione backup Sundata."

    # Aggiorna il file di stato con la nuova data di modifica
    echo "\$data_modifica_attuale" > "\$file_di_stato"

    # Cancello la copia del backup
    rm -f /opt/backup/\$allegato
fi

EOF

chmod +x /opt/backup/backup_check.sh

(crontab -l ; echo "0 * * * *  /opt/backup/backup_check.sh $bckfolder") | crontab -


echo "================================================================================================"
echo "Customization complete. Please reboot the device"
echo " "
rm -- "$0"
