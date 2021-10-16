FROM ubuntu:20.04
ARG DEBIAN_FRONTEND="noninteractive"

# For the VNC connection
EXPOSE 5900

# For the browser-based VNC client
EXPOSE 5901

# Use an enviornment variable to allow custom VNC passwords
ENV VNC_PASSWORD=123456

# Make sure the dependencies are set
RUN apt-get update \
    && apt-get install -y tigervnc-standalone-server fluxbox xterm git net-tools python python-numpy scrot wget software-properties-common vlc avahi-daemon curl \
    && sed -i 's/geteuid/getppid/' /usr/bin/vlc \
    && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:obsproject/obs-studio \
    && apt-get update \
    && apt-get install -y obs-studio \
    && rm -rf /var/lib/apt/lists/*

# Build and install everything.
RUN git config --global advice.detachedHead false \
    && noVNC_VERSION=$(curl -s "https://api.github.com/repos/novnc/noVNC/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/') \
    && websockify_VERSION=$(curl -s "https://api.github.com/repos/novnc/websockify/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/') \
    && git clone --branch "${noVNC_VERSION}" --single-branch https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone --branch "${websockify_VERSION}" --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
    && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html \
    && OBS_NDI_LATEST_RELEASE=$(curl -s https://api.github.com/repos/Palakis/obs-ndi/releases/latest) \
    && echo "${OBS_NDI_LATEST_RELEASE}" | grep "https://github.com/Palakis/obs-ndi/releases/download/" | grep "libndi" | grep "_amd64.deb" | cut -d : -f 2,3 | tr -d "\"" | wget -O /tmp/libndi_amd64.deb -qi - \
    && echo "${OBS_NDI_LATEST_RELEASE}" | grep "https://github.com/Palakis/obs-ndi/releases/download/" | grep "obs-ndi_" | grep "_amd64.deb" | cut -d : -f 2,3 | tr -d "\"" | wget -O /tmp/obs-ndi_amd64.deb -qi - \
    && wget -q -O obs-websocket_4.9.1-1_amd64.deb https://github.com/Palakis/obs-websocket/releases/download/4.9.1/obs-websocket_4.9.1-1_amd64.deb \

    # install the plugins for NDI
    && dpkg -i /tmp/*.deb \
    && rm -rf /tmp/*.deb \
    && rm -rf /var/lib/apt/lists/*

# Copy container_startup.sh to /opt, copy x11vnc_entrypoint.sh to /opt, copy startup.sh to /opt/startup_scripts
COPY ./container_startup.sh /opt/
COPY ./x11vnc_entrypoint.sh /opt/
COPY ./startup.sh /opt/startup_scripts/

RUN chmod +x /opt/*.sh \
    && chmod +x /opt/startup_scripts/*.sh \
    && mkdir -p /config /root/.config/ \
    && ln -s /config /root/.config/obs-studio

# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"OBS Studio\" command=\"obs\"" >> /usr/share/menu/custom-docker \
    && echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus
VOLUME ["/config"]
ENTRYPOINT ["/opt/container_startup.sh"]
