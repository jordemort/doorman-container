ARG USER_UID=1995
ARG USER_GID=$USER_UID
ARG QODEM_VERSION=1.0.1
ARG FIXUID_VERSION=0.6.0

########################################################################
# qodem
########################################################################

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

########################################################################
# fixuid
########################################################################

FROM ubuntu:22.04 AS fixuid

ARG FIXUID_VERSION

ADD https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-amd64.tar.gz /usr/src/fixuid.tar.gz

RUN tar -C /usr/local/bin -xzvf /usr/src/fixuid.tar.gz

########################################################################
# doorman
########################################################################

FROM ubuntu:22.04 AS doorman

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=qodem /usr/local /usr/local

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dumb-init \
        gnupg \
        less \
        libslang2 \
        locales \
        nano \
        net-tools \
        socat \
        software-properties-common \
        tmux && \
    add-apt-repository ppa:dosemu2/ppa && \
    apt-get update && \
    apt-get install -y dosemu2 && \
    apt-get clean

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

COPY --from=fixuid /usr/local/bin/fixuid /usr/local/bin/fixuid

RUN chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid

ARG USER_UID USER_GID

RUN groupadd -g ${USER_GID} doorman && useradd -m -u ${USER_UID} -g doorman -s /bin/bash doorman
RUN mkdir /var/run/user/${USER_UID} && chown doorman:doorman /var/run/user/${USER_UID}

USER doorman
WORKDIR /home/doorman
ENV USER=doorman SHELL=/bin/bash HOME=/home/doorman

RUN dosemu -dumb /usr/share/dosemu2-extras/bat/insfdusr.bat
RUN mkdir -p qodem/host .qodem/script && TERM=xterm qodem -x /bin/true

COPY --chown=doorman:doorman dosemurc /home/doorman/.dosemu/dosemurc

USER root

COPY fixuid-config.yml /etc/fixuid/config.yml
COPY bin/* /usr/local/bin/

RUN ln -s /usr/local/bin/sysop-cmd.sh /usr/local/bin/configure.sh && \
    ln -s /usr/local/bin/sysop-cmd.sh /usr/local/bin/nightly.sh

USER doorman

ENTRYPOINT [ "/usr/bin/dumb-init", "/usr/local/bin/fixuid", "-q", "--", "/usr/local/bin/entrypoint.sh" ]
