#!/bin/bash

echo "This was the commands that will set the icons at the center of that position, This will set the icon at the bottom-center"

sudo apt update
sudo apt install gnome-shell-extension-dashtodock
sudo apt install chrome-gnome-shell gnome-shell-extension-prefs
gnome-extensions enable dash-to-dock@micxgx.gmail.com
gsettings set org.gnome.shell.extensions.dash-to-dock always-center-icons true
