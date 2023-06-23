#!/bin/sh /etc/rc.common
#By krabelize | cryptsus.com
#MAC address changer script

#Modified by Chronnox for use in Webbrowser. Also replaced 'ifconfig'-command with 'uci'
#MAKE SURE the 'oui_prefix' of the MAC address matches a client side NIC vendor. find one here 'https://ouilookup.com/'
#Change 'interface' to the desired interface you want to change
#Save file as for example 'reconnect.sh' and place this script in '/www/cgi/' and make it executable (i.e. chmod +x reconnect.sh)
#Open script via webbrowser like: 'https://[routerIP/hostname]/cgi-bin/reconnect.sh'

#Only tested with WAN Interface
#Worked everytime so not sure if failed and missing system utilities messages work


#change these
oui_prefix='34:81:C4:'
interface='wan'

#find device name for chosen interface in uci
deviceno=$(uci show network | grep $interface | grep @device | awk -F [\]\[] '{print$2}')
cfgname=$(uci show network.@device[$deviceno].name | awk -F. '{print$2}')

#find current MAC address
current_mac=$(uci show network.@device[$deviceno].macaddr | awk -F\' '{print $2}')

#create new MAC address
new_mac=$(dd if=/dev/random bs=1 count=3 2>/dev/null | hexdump -C | head -1 | cut -d' ' -f2- | awk -v awkvar="$oui_prefix" '{ print awkvar$1":"$2":"$3 }')
if [ $? -eq 0 ]; then
   #set new MAC address, commit changes to be visible in LUCI and reload config to take effect
   uci set network.$cfgname.macaddr=$new_mac
   uci commit network
   reload_config
      #check for success
      if [ $? -eq 0 ]; then
         logger 'MAC address successfully changed for $interface from $current_mac to $new_mac'
         changed_mac=$(uci show network.@device[$deviceno].macaddr | awk -F\' '{print $2}')
         logger 'New MAC address: $current_mac'
         echo "Content-type: text/html"
         echo
         echo "<html><head><title>Successful change of WAN MAC</title></head><body><p>MAC address successfully changed for $interface from $current_mac to $changed_mac</p></body></html>"
         exit 0
      #if change failed
      else
         logger 'MAC address changing scriped failed'
         echo "Content-type: text/html"
         echo
         echo "<html><head><title>Unsuccessful change of WAN MAC</title></head><body><p>MAC address changing scriped failed</p></body></html>"
         exit 1
      fi
#missing system utilities
else
   logger 'Failed to generate MAC address. Perhaps you are missing certain system utilities'
   exit 1
fi
