FROM debian:unstable

RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install -y --force-yes gcc-arm-linux-gnueabihf distcc && \
    rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/bin/arm-linux-gnueabihf-gcc /usr/bin/gcc
EXPOSE 3632
CMD ["/usr/bin/distccd", "--listen", "0.0.0.0", "--allow", "0.0.0.0/0", "--daemon", "--no-detach"]
