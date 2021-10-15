#!/bin/bash
/etc/init.d/dbus start
/etc/init.d/avahi-daemon start
ln -s /config /root/.config/obs-studio
