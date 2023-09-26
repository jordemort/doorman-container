ARG USERNAME=doorman
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG QODEM_VERSION=1.0.1

##########

FROM ubuntu:22.04 AS qodem

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y build-essential checkinstall libncurses-dev

ARG QODEM_VERSION

ADD https://downloads.sourceforge.net/project/qodem/qodem/${QODEM_VERSION}/qodem-${QODEM_VERSION}.tar.gz /usr/src/qodem-${QODEM_VERSION}.tar.gz

WORKDIR /usr/src

RUN tar -xzvf /usr/src/qodem-${QODEM_VERSION}.tar.gz

WORKDIR /usr/src/qodem-${QODEM_VERSION}

RUN ./configure --prefix=/usr/local --disable-sdl --disable-x11 --disable-ssh --disable-upnp --disable-gpm && \
    make && \
    make install

##########

FROM ubuntu:22.04 AS doorman

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=qodem /usr/local /usr/local

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dumb-init \
        evilwm \
        gnupg \
        less \
        locales \
        nano \
        net-tools \
        socat \
        software-properties-common \
        tigervnc-standalone-server \
        tigervnc-tools \
        x11-utils \
        xfonts-base \
        xfonts-scalable && \
    add-apt-repository ppa:dosemu2/ppa && \
    apt-get update && \
    apt-get install -y dosemu2 && \
    apt-get clean

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

ARG USERNAME USER_UID USER_GID

RUN groupadd -g ${USER_GID} ${USERNAME} && useradd -m -u ${USER_UID} -g ${USERNAME} -s /bin/bash ${USERNAME}
RUN mkdir /var/run/user/${USER_UID} && chown ${USERNAME}:${USERNAME} /var/run/user/${USER_UID}

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV USER=${USERNAME} SHELL=/bin/bash

RUN dosemu -dumb /usr/share/dosemu2-extras/bat/insfdusr.bat
RUN TERM=xterm qodem -x /bin/true
RUN mkdir -p /home/${USERNAME}/.vnc

COPY --chown=${USERNAME}:${USERNAME} dosemurc /home/${USERNAME}/.dosemu/dosemurc
COPY --chown=${USERNAME}:${USERNAME} Xtigervnc-session /home/${USERNAME}/.vnc/Xtigervnc-session

COPY wait-for-launch.sh /usr/local/bin
COPY launch.sh /usr/local/bin

ENTRYPOINT [ "/usr/bin/dumb-init" ]
