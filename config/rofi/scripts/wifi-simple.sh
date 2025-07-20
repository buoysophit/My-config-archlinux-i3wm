#!/bin/bash

# Simple WiFi menu for polybar
# This version is optimized for terminal testing and polybar integration

# Check if rofi is available
if ! command -v rofi &> /dev/null; then
    echo "Error: rofi is not installed"
    exit 1
fi

# Check if nmcli is available  
if ! command -v nmcli &> /dev/null; then
    echo "Error: NetworkManager (nmcli) is not installed"
    exit 1
fi

# Function to get menu items
get_menu_items() {
    {
        echo "🔄 Refresh Networks"
        echo "---"
        
        # Get current connection
        current=$(nmcli -t -f NAME c show --active 2>/dev/null | head -n1)
        if [ -n "$current" ] && [ "$current" != "lo" ]; then
            echo "󰖩 Connected: $current"
            echo "󰖪 Disconnect"
            echo "---"
        fi
        
        # Get available networks
        nmcli -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | tail -n +2 | while IFS= read -r line; do
            # Parse the line more carefully
            ssid=$(echo "$line" | awk '{print $1}')
            signal=$(echo "$line" | awk '{print $2}')
            
            # Validate signal is a number
            if ! [[ "$signal" =~ ^[0-9]+$ ]]; then
                signal=50  # Default signal strength
            fi
            
            if [ -n "$ssid" ] && [ "$ssid" != "--" ] && [ "$ssid" != "" ]; then
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
                
                # Check if network is secured (simple check)
                if echo "$line" | grep -q "WPA\|WEP"; then
                    security_icon=" 🔒"
                else
                    security_icon=""
                fi
                
                echo "$icon $ssid$security_icon"
            fi
        done | head -10 | sort -u
    }
}

# Function to handle selection
handle_selection() {
    selection="$1"
    
    case "$selection" in
        "🔄 Refresh Networks")
            nmcli dev wifi rescan 2>/dev/null
            # Relaunch the menu
            exec "$0"
            ;;
        "󰖪 Disconnect")
            nmcli dev disconnect wlan0 2>/dev/null
            notify-send "WiFi" "Disconnected from network" 2>/dev/null
            ;;
        "")
            # User cancelled
            exit 0
            ;;
        *)
            # Extract SSID from selection (remove icon and security indicator)
            ssid=$(echo "$selection" | sed 's/^[󰤯󰤟󰤢󰤥󰤨] *//' | sed 's/ 🔒$//')
            
            if [ -z "$ssid" ]; then
                exit 0
            fi
            
            # Check if network requires password by looking for security info
            if echo "$selection" | grep -q "🔒"; then
                # Network requires password
                password=$(echo "" | rofi -dmenu -password -p "Password for $ssid" -theme-str 'window {width: 400px;}')
                if [ -n "$password" ]; then
                    if nmcli dev wifi connect "$ssid" password "$password" 2>/dev/null; then
                        notify-send "WiFi" "Connected to $ssid" 2>/dev/null
                    else
                        rofi -e "Failed to connect to $ssid. Check your password." &
                    fi
                fi
            else
                # Open network
                if nmcli dev wifi connect "$ssid" 2>/dev/null; then
                    notify-send "WiFi" "Connected to $ssid" 2>/dev/null
                else
                    rofi -e "Failed to connect to $ssid" &
                fi
            fi
            ;;
    esac
}

# Main execution
if [ "$1" = "--test" ]; then
    # Test mode - just show what would be in the menu
    get_menu_items
else
    # Normal mode - show rofi menu
    selection=$(get_menu_items | rofi -dmenu -p "WiFi Networks" -theme-str 'window {width: 400px;}' -i)
    handle_selection "$selection"
fi
