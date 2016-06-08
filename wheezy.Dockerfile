FROM debian:wheezy

RUN echo "deb http://www.emdebian.org/debian/ unstable main" >> /etc/apt/sources.list
RUN apt-get update && \
    apt-get install -y --force-yes gcc-4.6-arm-linux-gnueabihf distcc && \
    rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/bin/arm-linux-gnueabihf-gcc-4.6 /usr/bin/arm-linux-gnueabihf-gcc
RUN ln -s /usr/bin/arm-linux-gnueabihf-gcc-4.6 /usr/bin/gcc
EXPOSE 3632
CMD ["/usr/bin/distccd", "--listen", "0.0.0.0", "--allow", "0.0.0.0/0", "--daemon", "--no-detach"]
