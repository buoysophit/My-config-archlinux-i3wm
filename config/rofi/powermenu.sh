#!/bin/bash

options=" Lock\n Shutdown\n Reboot\n Suspend\n Logout"
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu")

case "$chosen" in
  " Lock") i3lock ;;
  " Shutdown") systemctl poweroff ;;
  " Reboot") systemctl reboot ;;
  " Suspend") systemctl suspend ;;
  " Logout") i3-msg exit ;;
esac

