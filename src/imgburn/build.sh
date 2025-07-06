#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

function log {
    echo ">>> $*"
}

IMGBURN_URL="${1:-}"
IMGBURN_SHA256="${2:-}"

if [ -z "$IMGBURN_URL" ]; then
    log "ERROR: ImgBurn URL missing."
    exit 1
fi

if [ -z "$IMGBURN_SHA256" ]; then
    log "ERROR: ImgBurn checksum missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    shadow \
    coreutils \
    su-exec \
    wget \
    cabextract \
    wine \

#
# Download sources.
#

log "Downloading ImgBurn..."
curl -# -L -f -o /tmp/ImgBurnInstaller.exe ${IMGBURN_URL}

if ! echo "$IMGBURN_SHA256 /tmp/ImgBurnInstaller.exe" | sha256sum --check --status
then
    log "ERROR: ImgBurn checksum check failed."
    exit 1
fi

#
# Install ImgBurn.
#

export WINEPREFIX=/opt/ImgBurn
export WINEDLLOVERRIDES="mscoree="
export XDG_CACHE_HOME=/tmp/xdg_cache

log "Creating Wine environment..."
useradd --system app
mkdir "$WINEPREFIX"
chown app:app "$WINEPREFIX"
su-exec app wineboot -i
su-exec app winecfg -v winxp
su-exec app wineserver -w

log "Installing ImgBurn..."

su-exec app wine /tmp/ImgBurnInstaller.exe /S
su-exec app wineserver -w

log "Adjusting Wine environment..."

# Enable font smoothing.
su-exec app winetricks fontsmooth=rgb

# Install Verdana font.
su-exec app winetricks fonts verdana

# Create symlink for the temporary directory.
rm -r "$WINEPREFIX"/drive_c/users/app/AppData/Local/Temp
ln -s /tmp "$WINEPREFIX"/drive_c/users/app/AppData/Local/Temp

# Languages are stored outside the container because language packs are
# install by user.
rm -r "$WINEPREFIX"/drive_c/"Program Files"/ImgBurn/Languages

su-exec app wineserver -w
rm "$WINEPREFIX"/winetricks.log

chown -R root:root "$WINEPREFIX"

# Move registry files.
mkdir /defaults
for regfpath in "$WINEPREFIX"/*.reg; do
    regfname="$(basename "$regfpath")"
    mv -v "$regfpath" /defaults/
    ln -s /tmp/"$regfname" "$regfpath"
done
