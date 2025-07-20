#!/bin/bash

# WiFi menu wrapper for polybar
# This script shows the rofi menu and handles selections

SCRIPT_DIR="$HOME/.config/rofi/scripts"
WIFI_SCRIPT="$SCRIPT_DIR/rofi-wifi-menu.sh"

# Function to get menu items
get_menu_items() {
    echo "🔄 Refresh"
    echo "---"
    
    # Get current connection
    current=$(nmcli -t -f NAME c show --active | head -n1)
    if [ -n "$current" ]; then
        echo "󰖩 Connected: $current"
        echo "---"
        echo "󰖪 Disconnect"
        echo "---"
    fi
    
    # Get available networks
    nmcli -f SSID,SIGNAL,SECURITY dev wifi list | tail -n +2 | while read -r line; do
        ssid=$(echo "$line" | awk '{print $1}')
        signal=$(echo "$line" | awk '{print $2}')
        security=$(echo "$line" | awk '{$1=$2=""; print $0}' | xargs)
        
        if [ -n "$ssid" ] && [ "$ssid" != "--" ]; then
            # Convert signal strength to icons
            if [ "$signal" -ge 80 ]; then
                icon="󰤨"
            elif [ "$signal" -ge 60 ]; then
                icon="󰤥"
            elif [ "$signal" -ge 40 ]; then
                icon="󰤢"
            elif [ "$signal" -ge 20 ]; then
                icon="󰤟"
            else
                icon="󰤯"
            fi
            
            # Add security indicator
            if [ -n "$security" ] && [ "$security" != "--" ]; then
                security_icon="🔒"
            else
                security_icon=""
            fi
            
            echo "$icon $ssid $security_icon"
        fi
    done | sort -u
}

# Function to handle selection
handle_selection() {
    selection="$1"
    case "$selection" in
        "🔄 Refresh")
            nmcli dev wifi rescan
            exec "$0"
            ;;
        "󰖪 Disconnect")
            nmcli dev disconnect wlan0
            notify-send "WiFi" "Disconnected from network" 2>/dev/null || echo "Disconnected"
            ;;
        "")
            exit 0
            ;;
        *)
            # Extract SSID from selection
            ssid=$(echo "$selection" | sed 's/^[^ ]* //' | sed 's/ 🔒$//')
            
            # Check if network requires password
            security=$(nmcli -f SSID,SECURITY dev wifi list | grep "^$ssid " | awk '{$1=""; print $0}' | xargs)
            
            if [ -n "$security" ] && [ "$security" != "--" ] && [ "$security" != "" ]; then
                # Network requires password
                password=$(rofi -dmenu -password -p "Password for $ssid" -theme-str 'window {width: 400px;}')
                if [ -n "$password" ]; then
                    if nmcli dev wifi connect "$ssid" password "$password" 2>/dev/null; then
                        notify-send "WiFi" "Connected to $ssid" 2>/dev/null || echo "Connected to $ssid"
                    else
                        notify-send "WiFi" "Failed to connect to $ssid" 2>/dev/null
                        rofi -e "Failed to connect to $ssid. Check your password."
                    fi
                fi
            else
                # Open network
                if nmcli dev wifi connect "$ssid" 2>/dev/null; then
                    notify-send "WiFi" "Connected to $ssid" 2>/dev/null || echo "Connected to $ssid"
                else
                    notify-send "WiFi" "Failed to connect to $ssid" 2>/dev/null
                    rofi -e "Failed to connect to $ssid"
                fi
            fi
            ;;
    esac
}

# Main execution
selection=$(get_menu_items | rofi -dmenu -p "WiFi Networks" -theme-str 'window {width: 400px;}' -i)
handle_selection "$selection"
