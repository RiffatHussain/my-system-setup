#!/bin/bash

echo "This was the commands that will set the icons at the center of that position, This will set the icon at the bottom-center"

sudo apt update
sudo apt install gnome-shell-extension-dashtodock
sudo apt install chrome-gnome-shell gnome-shell-extension-prefs
gnome-extensions enable dash-to-dock@micxgx.gmail.com
gsettings set org.gnome.shell.extensions.dash-to-dock always-center-icons true



Mac OS customization

1803  gnome-extensions disable ubuntu-dock@ubuntu.com
 1804  gnome-extensions list --enabled
 1805  gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
 1806  gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
 1807  gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
 1808  gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
 1809  gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-previews'
 1810  gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
 1811  gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.4
 1812  gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Dark'
 1813  gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
 1814  gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
 1815  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
 1816  gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Dark'
 1817  gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
 1818  gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
 1819  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
