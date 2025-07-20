#!/bin/bash

# WiFi menu script for rofi
# Shows available WiFi networks and allows connection
# Place this file at: ~/.config/rofi/scripts/rofi-wifi-menu.sh
# Make it executable with: chmod +x ~/.config/rofi/scripts/rofi-wifi-menu.sh

# Get list of available networks
get_networks() {
    nmcli -t -f SSID,BARS,SECURITY dev wifi | grep -v '^--' | sort -t: -k2nr | while IFS=: read -r ssid bars security; do
        if [ -n "$ssid" ]; then
            # Convert signal bars to icons
            case $bars in
                "▂___") icon="󰤯" ;;
                "▂▄__") icon="󰤟" ;;
                "▂▄▆_") icon="󰤢" ;;
                "▂▄▆█") icon="󰤨" ;;
                *) icon="󰤥" ;;
            esac
            
            # Add security indicator
            if [ -n "$security" ] && [ "$security" != "--" ]; then
                security_icon="🔒"
            else
                security_icon=""
            fi
            
            echo "$icon $ssid $security_icon"
        fi
    done
}

# Get currently connected network
get_current_network() {
    current=$(nmcli -t -f NAME c show --active | grep -v lo | head -n1)
    if [ -n "$current" ]; then
        echo "󰖩 Connected: $current"
        echo "---"
        echo "󰖪 Disconnect"
        echo "---"
    fi
}

# Handle user selection
if [ -z "$1" ]; then
    # First run - show menu
    echo "🔄 Refresh"
    echo "---"
    get_current_network
    get_networks
else
    case "$1" in
        "🔄 Refresh")
            # Refresh networks
            nmcli dev wifi rescan
            exec "$0"
            ;;
        "󰖪 Disconnect")
            # Disconnect from current network
            nmcli dev disconnect wlan0
            notify-send "WiFi" "Disconnected from network"
            ;;
        *)
            # Extract SSID from selection (remove icon and security indicator)
            ssid=$(echo "$1" | sed 's/^[^ ]* //' | sed 's/ 🔒$//')
            
            # Check if network requires password
            security=$(nmcli -t -f SSID,SECURITY dev wifi | grep "^$ssid:" | cut -d: -f2)
            
            if [ -n "$security" ] && [ "$security" != "--" ]; then
                # Network requires password
                password=$(rofi -dmenu -password -p "Password for $ssid: " -theme-str 'window {width: 400px;}')
                if [ -n "$password" ]; then
                    if nmcli dev wifi connect "$ssid" password "$password"; then
                        notify-send "WiFi" "Connected to $ssid"
                    else
                        notify-send "WiFi" "Failed to connect to $ssid"
                        rofi -e "Failed to connect to $ssid. Check your password."
                    fi
                fi
            else
                # Open network
                if nmcli dev wifi connect "$ssid"; then
                    notify-send "WiFi" "Connected to $ssid"
                else
                    notify-send "WiFi" "Failed to connect to $ssid"
                    rofi -e "Failed to connect to $ssid"
                fi
            fi
            ;;
    esac
fi
