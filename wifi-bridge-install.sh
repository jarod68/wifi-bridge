#!/bin/bash

# ############################################################################
# Author:               Matthieu Holtz
# Year:                 2017
# Project:              wifi bridge
# Description:  	Installation script
# ############################################################################

my_dir=`pwd`
timestamp=`date`
echo $my_dir
source "$my_dir/wifi-helpers"

SERVICE_NAME="wifi-bridge"
INITD_SCRIPT_PATH="/etc/init.d/$SERVICE_NAME"

#sudo apt-get update

EchoStatus $? "Packet manager update"

#sudo apt-get -y install wireless-tools wpasupplicant isc-dhcp-client isc-dhcp-server sed iptables

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

# /!\ $1 is the argument of the service script, not the install script
echo 'case "$1" in' >> "$INITD_SCRIPT_PATH"
echo "  start)" >> "$INITD_SCRIPT_PATH"
echo '    echo "Starting..."' >> "$INITD_SCRIPT_PATH"
echo "    $my_dir/wifi-bridge-setup.sh" >> "$INITD_SCRIPT_PATH"
echo "    exit 0" >> "$INITD_SCRIPT_PATH"
echo "    ;;" >> "$INITD_SCRIPT_PATH"
echo "  stop)" >> "$INITD_SCRIPT_PATH"
echo '    echo "Stoping..."' >> "$INITD_SCRIPT_PATH"
echo "    KillProcess" >> "$INITD_SCRIPT_PATH"
echo "    exit 0" >> "$INITD_SCRIPT_PATH"
echo "    ;;" >> "$INITD_SCRIPT_PATH"
echo "  *)" >> "$INITD_SCRIPT_PATH"
echo '    echo "Usage: '"$INITD_SCRIPT_PATH" '{start|stop}"' >> "$INITD_SCRIPT_PATH"
echo "    exit 1" >> "$INITD_SCRIPT_PATH"
echo "    ;;" >> "$INITD_SCRIPT_PATH"
echo "esac" >> "$INITD_SCRIPT_PATH"

sed -i '2s/^/# Generated on '"$timestamp"'\n/' "$INITD_SCRIPT_PATH"

EchoStatus $? "Create $INITD_SCRIPT_PATH =>"

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

