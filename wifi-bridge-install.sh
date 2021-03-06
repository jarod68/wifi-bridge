#!/bin/bash

# ############################################################################
# Author:               Matthieu Holtz
# Year:                 2017
# Project:              wifi bridge
# Description:  	      Installation script
# ############################################################################

my_dir=`pwd`
timestamp=`date`

source "$my_dir/wifi-helpers"

SERVICE_NAME="wifi-bridge"
INITD_SCRIPT_PATH="/etc/init.d/$SERVICE_NAME"
SAMBA_SHARE_PATH="/share"
SAMBA_SHARE_PATH_LOG="/tmp/log"
SAMBA_CONFIG_PATH="/etc/wifi-bridge/smb.conf"
NGINX_CONFIG_PATH="/etc/wifi-bridge/nginx.conf"

if [ -d "/etc/wifi-bridge" ]; then  
   rm -R "/etc/wifi-bridge"
   EchoStatus $? "Delete /etc/wifi-bridge"
fi

mkdir -p "/etc/wifi-bridge"
EchoStatus $? "Create /etc/wifi-bridge"

sudo apt-get update

EchoStatus $? "Packet manager update"

sudo apt-get -y install wireless-tools wpasupplicant isc-dhcp-client isc-dhcp-server sed iptables samba nginx

EchoStatus $? "Packet manager install dependencies"

echo "#!/bin/bash" > "$INITD_SCRIPT_PATH"

echo "" >> "$INITD_SCRIPT_PATH"

echo "### BEGIN INIT INFO" >> "$INITD_SCRIPT_PATH"
echo "# Provides:          $SERVICE_NAME" >> "$INITD_SCRIPT_PATH"
echo "# Required-Start:    " >> "$INITD_SCRIPT_PATH"
echo "# Required-Stop:     " >> "$INITD_SCRIPT_PATH"
echo "# Default-Start:     2 3 4 5" >> "$INITD_SCRIPT_PATH"
echo "# Default-Stop:      0 1 6" >> "$INITD_SCRIPT_PATH"
echo "# Short-Description: $SERVICE_NAME" >> "$INITD_SCRIPT_PATH"
echo "# Description:       $SERVICE_NAME" >> "$INITD_SCRIPT_PATH"
echo "### END INIT INFO" >> "$INITD_SCRIPT_PATH"

echo "" >> "$INITD_SCRIPT_PATH"

#echo ". /lib/init/vars.sh" >> "$INITD_SCRIPT_PATH"
#echo ". /lib/lsb/init-functions" >> "$INITD_SCRIPT_PATH"
echo "source "'"'"$my_dir/wifi-helpers"'"' >> "$INITD_SCRIPT_PATH"

echo "" >> "$INITD_SCRIPT_PATH"

echo "function process_stop {" >> "$INITD_SCRIPT_PATH"
echo "    KillProcess" >> "$INITD_SCRIPT_PATH"
echo "    killall smbd" >> "$INITD_SCRIPT_PATH"
echo "    nginx -s stop" >> "$INITD_SCRIPT_PATH"
echo "    killall nginx" >> "$INITD_SCRIPT_PATH"
echo '    if [ -f /tmp/checkup_proc_pid ]' >> "$INITD_SCRIPT_PATH"
echo '    then' >> "$INITD_SCRIPT_PATH"
echo '      PID_TO_KILL=`cat /tmp/checkup_proc_pid`' >> "$INITD_SCRIPT_PATH"
echo '      kill -9 $PID_TO_KILL' >> "$INITD_SCRIPT_PATH"
echo '      rm /tmp/checkup_proc_pid' >> "$INITD_SCRIPT_PATH"
echo '    fi' >> "$INITD_SCRIPT_PATH"
echo "}" >> "$INITD_SCRIPT_PATH"

echo "" >> "$INITD_SCRIPT_PATH"

echo "function process_start {" >> "$INITD_SCRIPT_PATH"
echo '    echo "Creating /tmp/wifi-bridge-checkup.sh"' >> "$INITD_SCRIPT_PATH"
echo '    mkdir -p "'"$SAMBA_SHARE_PATH_LOG"'"' >> "$INITD_SCRIPT_PATH"
echo '    echo "'"$SAMBA_SHARE_PATH_LOG"'" > /tmp/wifi-bridge-log-path' >> "$INITD_SCRIPT_PATH"

echo '    echo "#!/bin/bash" > /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "while :" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "do" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "  ping -q -c2 www.google.com > /dev/null" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
#the $ here is because the quote owns a quote inside...bash trick
echo $'    echo \'  if [ $? -ne 0 ]\' >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "  then" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo $'    echo \'  if [ $(wc -l < "'$SAMBA_SHARE_PATH_LOG$'/wifi-bridge-checkup.log") -ge 1024 ]; then rm "'$SAMBA_SHARE_PATH_LOG$'/wifi-bridge-checkup.log"; fi\' >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"

echo '    echo "'"    $my_dir/wifi-bridge-setup.sh"'" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "   date -u >> '"$SAMBA_SHARE_PATH_LOG"'/wifi-bridge-checkup.log" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "   echo Restart wifi-bridge on ping error >> '"$SAMBA_SHARE_PATH_LOG"'/wifi-bridge-checkup.log" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "   echo --- >> '"$SAMBA_SHARE_PATH_LOG"'/wifi-bridge-checkup.log" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "  fi" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "  sleep 15m" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "done" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "#Should never reach this point!" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    echo "exit 1" >> /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo '    chmod 777 /tmp/wifi-bridge-checkup.sh' >> "$INITD_SCRIPT_PATH"
echo "    $my_dir/wifi-bridge-setup.sh" >> "$INITD_SCRIPT_PATH"
echo '    /tmp/wifi-bridge-checkup.sh &' >> "$INITD_SCRIPT_PATH"
echo '    CHECKUP_PROC_PID=$!' >> "$INITD_SCRIPT_PATH"
echo '    echo "$CHECKUP_PROC_PID" > /tmp/checkup_proc_pid' >> "$INITD_SCRIPT_PATH"
echo '    echo "Launch /tmp/wifi-bridge-checkup.sh with PID $CHECKUP_PROC_PID"' >> "$INITD_SCRIPT_PATH"
echo "    # Start samba" >> "$INITD_SCRIPT_PATH"
echo "    smbd -s $SAMBA_CONFIG_PATH" >> "$INITD_SCRIPT_PATH"
echo "    # Start nginx" >> "$INITD_SCRIPT_PATH"
echo "    nginx -c $NGINX_CONFIG_PATH" >> "$INITD_SCRIPT_PATH"
echo "}" >> "$INITD_SCRIPT_PATH"

echo "" >> "$INITD_SCRIPT_PATH"

# /!\ $1 is the argument of the service script, not the install script
echo 'case "$1" in' >> "$INITD_SCRIPT_PATH"

echo '##################' >> "$INITD_SCRIPT_PATH"
echo '# Start handling #' >> "$INITD_SCRIPT_PATH"
echo '##################' >> "$INITD_SCRIPT_PATH"

echo "  start)" >> "$INITD_SCRIPT_PATH"
echo '    echo "Starting..."' >> "$INITD_SCRIPT_PATH"
echo "    process_stop" >> "$INITD_SCRIPT_PATH"
echo "    process_start" >> "$INITD_SCRIPT_PATH"
echo "    exit 0" >> "$INITD_SCRIPT_PATH"
echo "    ;;" >> "$INITD_SCRIPT_PATH"

echo '#################' >> "$INITD_SCRIPT_PATH"
echo '# Stop handling #' >> "$INITD_SCRIPT_PATH"
echo '#################' >> "$INITD_SCRIPT_PATH"

echo "  stop)" >> "$INITD_SCRIPT_PATH"
echo '    echo "Stoping..."' >> "$INITD_SCRIPT_PATH"
echo "    process_stop" >> "$INITD_SCRIPT_PATH"
echo "    exit 0" >> "$INITD_SCRIPT_PATH"
echo "    ;;" >> "$INITD_SCRIPT_PATH"

echo '##################' >> "$INITD_SCRIPT_PATH"
echo '# Other handling #' >> "$INITD_SCRIPT_PATH"
echo '##################' >> "$INITD_SCRIPT_PATH"

echo "  *)" >> "$INITD_SCRIPT_PATH"
echo '    echo "Usage: '"$INITD_SCRIPT_PATH" '{start|stop}"' >> "$INITD_SCRIPT_PATH"
echo "    exit 1" >> "$INITD_SCRIPT_PATH"
echo "    ;;" >> "$INITD_SCRIPT_PATH"
echo "esac" >> "$INITD_SCRIPT_PATH"

echo '# End of autogenerated service script' >> "$INITD_SCRIPT_PATH"

sed -i '2s/^/# Generated on '"$timestamp"'\n/' "$INITD_SCRIPT_PATH"

echo "Create $INITD_SCRIPT_PATH =>"

cat "$INITD_SCRIPT_PATH"

sudo chmod +x "$INITD_SCRIPT_PATH"
sudo chown root:root "$INITD_SCRIPT_PATH"

EchoStatus $? "Set service file perm"

sudo update-rc.d "$SERVICE_NAME" defaults

EchoStatus $? "Add service with default start settings"

sudo update-rc.d "$SERVICE_NAME" enable

EchoStatus $? "Enable service"

rm /usr/share/dbus-1/system-services/fi.epitest.hostap.WPASupplicant.service

EchoStatus $? "Deactivate other wpa_supplicant"

mv "/etc/wpa_supplicant/wpa_supplicant.conf" "/etc/wpa_supplicant/wpa_supplicant.conf.bak"

EchoStatus $? "mv existing wpa_supplicant if exist (NOK is not exist)"

mkdir -p "$SAMBA_SHARE_PATH"
chmod 777 "$SAMBA_SHARE_PATH"
EchoStatus $? "$SAMBA_SHARE_PATH creation"

mkdir -p "$SAMBA_SHARE_PATH_LOG"
chmod 777 "$SAMBA_SHARE_PATH_LOG"
EchoStatus $? "$SAMBA_SHARE_PATH_LOG creation"

echo "[global]" > "$SAMBA_CONFIG_PATH"
echo "       workgroup = WORKGROUP" >> "$SAMBA_CONFIG_PATH"
echo "       netbios name = wifi-bridge" >> "$SAMBA_CONFIG_PATH"
echo "       map to guest = Bad User" >> "$SAMBA_CONFIG_PATH"
echo "       log file = /var/log/samba/%m" >> "$SAMBA_CONFIG_PATH"
echo "       log level = 1" >> "$SAMBA_CONFIG_PATH"
echo "" >> "$SAMBA_CONFIG_PATH"
echo "[share]" >> "$SAMBA_CONFIG_PATH"
echo "        # This share allows anonymous access" >> "$SAMBA_CONFIG_PATH"
echo "        path = $SAMBA_SHARE_PATH" >> "$SAMBA_CONFIG_PATH"
echo "        read only = no" >> "$SAMBA_CONFIG_PATH"
echo "        guest ok = yes" >> "$SAMBA_CONFIG_PATH"
echo "        Browseable = yes" >> "$SAMBA_CONFIG_PATH"
echo "        Writeable = Yes" >> "$SAMBA_CONFIG_PATH"
echo "        only guest = no" >> "$SAMBA_CONFIG_PATH"
echo "        create mask = 0777" >> "$SAMBA_CONFIG_PATH"
echo "        directory mask = 0777" >> "$SAMBA_CONFIG_PATH"
echo "        Public = yes" >> "$SAMBA_CONFIG_PATH"
echo "" >> "$SAMBA_CONFIG_PATH"
echo "[log]" >> "$SAMBA_CONFIG_PATH"
echo "        # This share allows anonymous access" >> "$SAMBA_CONFIG_PATH"
echo "        path = $SAMBA_SHARE_PATH_LOG" >> "$SAMBA_CONFIG_PATH"
echo "        read only = yes" >> "$SAMBA_CONFIG_PATH"
echo "        guest ok = yes" >> "$SAMBA_CONFIG_PATH"
echo "        Browseable = yes" >> "$SAMBA_CONFIG_PATH"
echo "        Writeable = no" >> "$SAMBA_CONFIG_PATH"
echo "        only guest = no" >> "$SAMBA_CONFIG_PATH"
echo "        create mask = 0777" >> "$SAMBA_CONFIG_PATH"
echo "        directory mask = 0777" >> "$SAMBA_CONFIG_PATH"
echo "        Public = yes" >> "$SAMBA_CONFIG_PATH"

sed -i '1s/^/# Generated on '"$timestamp"'\n/' "$SAMBA_CONFIG_PATH"

EchoStatus $? "$SAMBA_CONFIG_PATH setting up=>"
cat "$SAMBA_CONFIG_PATH"

echo 'worker_processes  1;' > "$NGINX_CONFIG_PATH"
echo 'pid /var/run/nginx.pid;' >> "$NGINX_CONFIG_PATH"
echo 'events {' >> "$NGINX_CONFIG_PATH"
echo '  worker_connections  128;' >> "$NGINX_CONFIG_PATH"
echo '}' >> "$NGINX_CONFIG_PATH"
echo '' >> "$NGINX_CONFIG_PATH"
echo 'http {' >> "$NGINX_CONFIG_PATH"

echo '  server {' >> "$NGINX_CONFIG_PATH"
echo '    listen 80;' >> "$NGINX_CONFIG_PATH"

echo '    location / {' >> "$NGINX_CONFIG_PATH"
echo "      root $SAMBA_SHARE_PATH_LOG;" >> "$NGINX_CONFIG_PATH"
echo '      autoindex on;' >> "$NGINX_CONFIG_PATH"
echo '    }' >> "$NGINX_CONFIG_PATH"
echo '  }' >> "$NGINX_CONFIG_PATH"
echo '}' >> "$NGINX_CONFIG_PATH"

sed -i '1s/^/# Generated on '"$timestamp"'\n/' "$NGINX_CONFIG_PATH"

EchoStatus $? "$NGINX_CONFIG_PATH setting up=>"
cat "$NGINX_CONFIG_PATH"

update-rc.d apache2 disable
EchoStatus $? "Disable apache2 autostart (if not install could be NOK)"

update-rc.d -f nginx disable
EchoStatus $? "Disable nginx autostart"

