#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Make sure required directories exist.
mkdir -p \
    /config/"Graph Data Files" \
    /config/"Project Files" \
    /config/"Queue Files" \
    /config/Languages \
    /config/log/ImgBurn \

# Install default configuration file.
[ -f /config/ImgBurn.ini ] || cp -v /defaults/ImgBurn.ini /config/ImgBurn.ini

# Copy registry files.
for F in user.reg system.reg userdef.reg; do
    cp -v /defaults/"$F" /tmp/
    chown "$USER_ID:$GROUP_ID" /tmp/"$F"
done

# Wine requires the WINEPREFIX directory to be owned by the user running the
# Windows app.
chown "$USER_ID:$GROUP_ID" "$WINEPREFIX"

# Enable CJK font in Wine if needed. Otherwise set Verdana as default font.
if is-bool-val-true "${ENABLE_CJK_FONT:-0}"; then
    su-exec app wine regedit /defaults/chn_fonts.reg
else
    su-exec app wine reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes' /v "Tahoma" /t REG_SZ /d "Verdana" /f
    su-exec app wine reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes' /v "MS Shell Dlg" /t REG_SZ /d "Verdana" /f
    su-exec app wine reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes' /v "MS Shell Dlg 2" /t REG_SZ /d "Verdana" /f
fi

# Handle dark mode.
if is-bool-val-true "${DARK_MODE:-0}"; then
    su-exec app wine regedit /defaults/wine-breeze-dark.reg
fi

# Wait for the wine server to terminate.
su-exec app wineserver -w

# Create optical drive(s) under DosDevices.
# NOTE: Drives will be mounted later via MountMgr.
DRV_NUM=0
lsscsi -k | grep -w "cd/dvd" | tr -s ' ' | while read -r DRV
do
    SR_DEV="$(echo "$DRV" | rev | awk '{print $1}' | rev)"
    ln -sf "$SR_DEV" /opt/ImgBurn/dosdevices/"$(echo "$DRV_NUM" | tr '0123456789' 'defghijklm')::"
    DRV_NUM="$(expr "$DRV_NUM" + 1)"
    [ "$DRV_NUM" -le 9 ] || break
done

# vim:ft=sh:ts=4:sw=4:et:sts=4
