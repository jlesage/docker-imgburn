#
# imgburn Dockerfile
#
# https://github.com/jlesage/docker-imgburn
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG IMGBURN_VERSION=2.5.8.0
ARG WINETRICKS_VERSION=20250102

# Define software download URLs.
ARG IMGBURN_URL=https://download.imgburn.com/SetupImgBurn_${IMGBURN_VERSION}.exe
ARG WINETRICKS_URL=https://github.com/Winetricks/winetricks/archive/refs/tags/${WINETRICKS_VERSION}.tar.gz

# Defune software checksums.
ARG IMGBURN_SHA256=49aa06eaffe431f05687109fee25f66781abbe1108f3f8ca78c79bdec8753420

# Build winetricks.
FROM alpine:3.22 AS winetricks
ARG WINETRICKS_URL
RUN \
    apk --no-cache add curl make && \
    mkdir /tmp/winetricks && \
    curl -# -L -f "$WINETRICKS_URL" | tar xz --strip 1 -C /tmp/winetricks && \
    DESTDIR=/tmp/winetricks-install make -C /tmp/winetricks install

# Build tool to add CD-ROM drives to Wine.
FROM alpine:3.22 AS wine-add-drive
COPY src/add_drive /build
RUN /build/build.sh

# Build ImgBurn.
FROM alpine:3.22 AS imgburn
ARG TARGETPLATFORM
ARG IMGBURN_URL
ARG IMGBURN_SHA256
COPY --from=winetricks /tmp/winetricks-install /
COPY src/imgburn /build
RUN if [ "$TARGETPLATFORM" != "linux/386" ]; then \
        echo "ERROR: ImgBurn should be built for linux/386 only."; \
        exit 1; \
    fi
RUN /build/build.sh "$IMGBURN_URL" "$IMGBURN_SHA256"

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.22-v4.8.2

ARG IMGBURN_VERSION
ARG DOCKER_IMAGE_VERSION

# Define working directory.
WORKDIR /tmp

# Install Wine.
RUN \
    add-pkg \
        gnutls \
        wine \
        # For optical drive listing.
        lsscsi

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/imgburn-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=imgburn /opt/ImgBurn /opt/ImgBurn
COPY --from=imgburn /defaults /defaults
COPY --from=wine-add-drive /tmp/add_drive.exe /opt/ImgBurn/drive_c/windows/
COPY --from=wine-add-drive /tmp/add_drive.exe.so /opt/ImgBurn/drive_c/windows/
COPY --from=winetricks /tmp/winetricks-install /

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "ImgBurn" && \
    set-cont-env APP_VERSION "$IMGBURN_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Define mountable directories.
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="imgburn" \
      org.label-schema.description="Docker container for ImgBurn" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-imgburn" \
      org.label-schema.schema-version="1.0"
