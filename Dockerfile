################################################################################
FROM francois75/docker-authfromhost:debian-stretch
MAINTAINER Francois Scala "github@arcenik.net"

ENV SAMBA_VERSION "4.9.0"
ENV SAMBA_MIRROR  "https://download.samba.org/pub/samba/"

################################################################################
WORKDIR /usr/src
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -yq &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -yq \
    bison flex faketime perl perl-modules \
    libacl1-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
    libcap-dev libcups2-dev libgnutls28-dev libldap2-dev libldb-dev \
    libncurses5-dev libntdb-dev libpam0g-dev libpcap-dev libpopt-dev \
    libreadline-dev libsubunit-dev libtalloc-dev libtdb-dev libtevent-dev \
    python-all-dev python-dnspython python-ldb python-ldb-dev python-ntdb \
    python-testtools python3 subunit xsltproc zlib1g-dev wget &&\
  wget "${SAMBA_MIRROR}/samba-pubkey.asc" &&\
  wget "${SAMBA_MIRROR}/stable/samba-${SAMBA_VERSION}.tar.asc" &&\
  wget "${SAMBA_MIRROR}/stable/samba-${SAMBA_VERSION}.tar.gz" &&\
  gpg --import samba-pubkey.asc &&\
  gunzip samba-${SAMBA_VERSION}.tar.gz &&\
  gpg --verify samba-${SAMBA_VERSION}.tar.asc &&\
  tar xf samba-${SAMBA_VERSION}.tar

WORKDIR /usr/src/samba-${SAMBA_VERSION}
RUN ./configure &&\
  make -j6 &&\
  make -j6 install &&\
  ln -vs /usr/local/samba/bin/*  /usr/local/bin/ &&\
  ln -vs /usr/local/samba/sbin/* /usr/local/sbin/ &&\
  rm -rf /usr/src/samba-${SAMBA_VERSION} &&\
  rm -f /usr/src/samba-${SAMBA_VERSION}.tar &&\
  rm -f /usr/src/samba-${SAMBA_VERSION}.tar.asc &&\
  DEBIAN_FRONTEND=noninteractive apt-get remove --yes \
    bison flex faketime perl perl-modules \
    libacl1-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
    libcap-dev libcups2-dev libgnutls28-dev libldap2-dev libldb-dev \
    libncurses5-dev libntdb-dev libpam0g-dev libpcap-dev libpopt-dev \
    libreadline-dev libsubunit-dev libtalloc-dev libtdb-dev libtevent-dev \
    python-all-dev python-ldb-dev \
    wget make gcc python-all-dev

################################################################################
FROM francois75/docker-authfromhost:debian-stretch-slim

RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -yq &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -yq \
    supervisor

COPY files/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY files/supervisord/nmbd.conf     /etc/supervisor/conf.d/nmbd.conf
COPY files/supervisord/smbd.conf     /etc/supervisor/conf.d/smbd.conf

COPY --from=0 /usr/local/samba /usr/local/samba

WORKDIR /usr/local/samba/var

VOLUME [ "/usr/local/samba/etc", "/usr/local/samba/private", "/home" ]
EXPOSE 137/udp 138/udp 139 445

CMD ["/usr/bin/supervisord", "-n"]
