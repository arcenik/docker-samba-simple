################################################################################
FROM francois75/docker-authfromhost:debian-buster
MAINTAINER Francois Scala "github@arcenik.net"

ENV SAMBA_VERSION "4.15.7"
# SAMBA_FOLDER can be "stable" or "rc"
ENV SAMBA_FOLDER "stable"

ENV SAMBA_MIRROR  "https://download.samba.org/pub/samba/"

################################################################################
WORKDIR /usr/src
RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -yq &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -q -y -o Dpkg::Use-Pty=0 \
    docbook-xsl bison flex faketime perl perl-modules \
    libacl1-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
    libcap-dev libcups2-dev libgnutls28-dev libldap2-dev libldb-dev liblmdb-dev \
    libncurses5-dev libpam0g-dev libpcap-dev libpopt-dev \
    libreadline-dev libsubunit-dev libtalloc-dev libtdb-dev libtevent-dev \
    python-all-dev python-dnspython python-ldb python-ldb-dev \
    libjansson-dev libgpgme11-dev python3-dev libtasn1-bin libfam-dev \
    python-testtools python3 subunit xsltproc zlib1g-dev wget libparse-yapp-perl \
    libdbus-1-dev libicu-dev libtracker-sparql-2.0-dev python3-markdown \
    python3-dnspython &&\
  wget -nv "${SAMBA_MIRROR}/samba-pubkey.asc" &&\
  wget -nv "${SAMBA_MIRROR}/${SAMBA_FOLDER}/samba-${SAMBA_VERSION}.tar.asc" &&\
  wget -nv "${SAMBA_MIRROR}/${SAMBA_FOLDER}/samba-${SAMBA_VERSION}.tar.gz" &&\
  gpg --no-tty --import samba-pubkey.asc &&\
  gunzip samba-${SAMBA_VERSION}.tar.gz &&\
  gpg --no-tty --verify samba-${SAMBA_VERSION}.tar.asc &&\
  tar xf samba-${SAMBA_VERSION}.tar

WORKDIR /usr/src/samba-${SAMBA_VERSION}
RUN ./configure &&\
  make -j6 &&\
  make -j6 install &&\
  ln -vs /usr/local/samba/bin/*  /usr/local/bin/ &&\
  ln -vs /usr/local/samba/sbin/* /usr/local/sbin/

################################################################################
FROM francois75/docker-authfromhost:debian-buster-slim

RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -yq &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -yq \
    supervisor libfam0 libtracker-sparql-2.0

COPY files/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY files/supervisord/nmbd.conf     /etc/supervisor/conf.d/nmbd.conf
COPY files/supervisord/smbd.conf     /etc/supervisor/conf.d/smbd.conf

COPY --from=0 /usr/local/samba /usr/local/samba

WORKDIR /usr/local/samba/var

VOLUME [ "/usr/local/samba/etc", "/usr/local/samba/private", "/home" ]
EXPOSE 137/udp 138/udp 139 445

CMD ["/usr/bin/supervisord", "-n"]
