#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Read-only template built into the image. Not used as WINEPREFIX at runtime so
# the image can stay root-owned and the container can run with a read-only rootfs.
WINE_TEMPLATE=/opt/ImgBurn

# Make sure required directories exist.
mkdir -p \
    /config/"Graph Data Files" \
    /config/"Project Files" \
    /config/"Queue Files" \
    /config/Languages \
    /config/log/ImgBurn \

# Install default configuration file.
[ -f /config/ImgBurn.ini ] || cp -v /defaults/ImgBurn.ini /config/ImgBurn.ini

#
# Build a user-owned runtime WINEPREFIX.
#
# Wine only requires the top-level prefix directory to be owned by the user
# running it. Point WINEPREFIX at a writable location and link the static bulk
# from the image template so we never need to chown /opt/ImgBurn.
#
# Use /config (not /tmp): Docker's default tmpfs for /tmp is noexec, and Wine
# cannot map PE sections with PROT_EXEC from a noexec filesystem (page fault).
#
rm -rf "$WINEPREFIX"
mkdir "$WINEPREFIX"

# Copy registry files.
for F in user.reg system.reg userdef.reg; do
    cp -v /defaults/"$F" "$WINEPREFIX"/
done

# Copy the timestamp to avoid update of the prefix.
cp -a "$WINE_TEMPLATE/.update-timestamp" "$WINEPREFIX/.update-timestamp"

# Link the read-only drive_c from the image template.
ln -sfn "$WINE_TEMPLATE/drive_c" "$WINEPREFIX/drive_c"

# Copy dosdevices so it stays writable: optical drive symlinks are added below.
cp -a "$WINE_TEMPLATE/dosdevices" "$WINEPREFIX/dosdevices"

# Take ownership of the prefix.
chown -R "$USER_ID:$GROUP_ID" "$WINEPREFIX"

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
lsscsi -k | grep -w "cd/dvd" | tr -s ' ' | awk '{print $NF}' | while read -r SR_DEV
do
    DRV_LETTER="$(echo "$DRV_NUM" | tr '0123456789' 'defghijklm')"
    echo "creating drive $DRV_LETTER: for $SR_DEV..."
    ln -sf "$SR_DEV" "$WINEPREFIX/dosdevices/$DRV_LETTER::"
    DRV_NUM="$((DRV_NUM + 1))"
    [ "$DRV_NUM" -le 9 ] || break
done

# vim:ft=sh:ts=4:sw=4:et:sts=4
