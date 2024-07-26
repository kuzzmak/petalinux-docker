FROM ubuntu:22.04

ARG PLNX_VER=2023.2

# Name of the petalinux installer file, so we know what to run
ARG INSTALLER_NAME=PetaLinux-${PLNX_VER}-final-installer.run

RUN apt-get update && apt-get install sudo locales vim subversion git rsync bc lsb-release libtinfo5 -y

# Install petalinux dependencies
COPY plnx-env-setup.sh /tmp/plnx-env-setup.sh
RUN chmod +x /tmp/plnx-env-setup.sh
RUN /tmp/plnx-env-setup.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# make a petalinux user
RUN adduser --disabled-password --gecos '' petalinux && \
    usermod -aG sudo petalinux && \
    echo "petalinux ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN locale-gen en_US.UTF-8 && update-locale

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Setup user environment
USER petalinux
ENV HOME /home/petalinux
ENV LANG en_US.UTF-8
RUN mkdir /home/petalinux/project
ENV SHELL /bin/bash

# Install petalinux tools
COPY --from=installers ${INSTALLER_NAME} /installers/${PLNX_VER}/${INSTALLER_NAME}
WORKDIR /installers/${PLNX_VER}
RUN sudo chown petalinux:petalinux /installers/${PLNX_VER} && \
    sudo chmod +x ${INSTALLER_NAME} && \
    sudo mkdir -p /opt/petalinux/${PLNX_VER} && \
    sudo chown petalinux:petalinux /opt/petalinux/${PLNX_VER} && \
    ./${INSTALLER_NAME} --dir /opt/petalinux/${PLNX_VER} --skip_license && \
    rm /installers/${PLNX_VER}/${INSTALLER_NAME}

# Soure petalinux settings in the user's profile on containre start
USER root
RUN echo "/usr/sbin/in.tftpd --foreground --listen --address [::]:69 --secure /tftpboot" >> /etc/profile && \
    echo ". /opt/petalinux/${PLNX_VER}/settings.sh" >> /etc/profile && \
    echo ". /etc/profile" >> /root/.profile

USER petalinux

WORKDIR /home/petalinux/project

EXPOSE 69/udp

ENTRYPOINT ["/bin/bash", "-l"]
