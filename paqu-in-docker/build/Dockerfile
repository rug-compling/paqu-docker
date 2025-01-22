#
# PaQu in Docker
#
# To build and push to repository:
#
#     docker build -t registry.webhosting.rug.nl/compling/paqu:latest .
#     docker push registry.webhosting.rug.nl/compling/paqu:latest
#

FROM ubuntu:bionic

LABEL org.opencontainers.image.authors="Peter Kleiweg <p.c.j.kleiweg@rug.nl>"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    less \
    libgraphviz-dev \
    libxft2 \
    libxss1 \
    locales \
    mc \
    nano \
    tzdata

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/mod/Alpino/bin:/mod/Alpino/Tokenization
ENV PAQU=/mod/data
ENV ALPINO_HOME=/mod/Alpino

ADD alpino.tar.gz /mod
ADD init.sh entrypoint.sh /mod/etc/
ADD /opt/bin /opt/bin
ADD /opt/dbxml2/lib /opt/dbxml2/lib
RUN mkdir -p /mod/corpora
ADD cdb.dact cdb.dactx cdbdate cdbversion cdb.md /mod/corpora

# compatibility oude versie
RUN mkdir -p /mod/paqu && \
    ln -s /opt/bin /mod/paqu

EXPOSE 9000

ENTRYPOINT ["/mod/etc/entrypoint.sh"]
CMD ["run"]

