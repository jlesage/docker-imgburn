# Docker container for ImgBurn
[![Release](https://img.shields.io/github/release/jlesage/docker-imgburn.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-imgburn/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/imgburn/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/imgburn/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/imgburn?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/imgburn)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/imgburn?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/imgburn)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-imgburn/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-imgburn/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-imgburn)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [ImgBurn](https://www.imgburn.com).

The graphical user interface (GUI) of the application can be accessed through a
modern web browser, requiring no installation or configuration on the client

---

[![ImgBurn logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/imgburn-icon.png&w=110)](https://www.imgburn.com)[![ImgBurn](https://images.placeholders.dev/?width=224&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=ImgBurn&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.imgburn.com)

ImgBurn is a lightweight CD / DVD / HD DVD / Blu-ray burning application
that everyone should have in their toolkit!
ImgBurn is a lightweight CD/DVD/Blu-ray burning application that supports
creating, writing, and verifying disc images. It handles a wide range of
image formats and offers advanced options for precise control over the
burning process.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

Launch the ImgBurn docker container with the following command:
```shell
docker run -d \
    --name=imgburn \
    -p 5800:5800 \
    -v /docker/appdata/imgburn:/config:rw \
    -v /home/user:/storage:rw \
    --device /dev/sr0 \
    jlesage/imgburn
```

Where:

  - `/docker/appdata/imgburn`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.
  - `/dev/sr0`: Linux device file corresponding to the optical drive.

Access the ImgBurn GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-imgburn.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-imgburn/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
