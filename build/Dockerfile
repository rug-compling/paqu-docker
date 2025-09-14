
FROM ubuntu:jammy

LABEL org.opencontainers.image.authors="Peter Kleiweg <p.c.j.kleiweg@rug.nl>"

RUN apt-get update && apt-get install -y tzdata && \
    echo "Europe/Amsterdam" > /etc/timezone && \
    rm -f /etc/localtime && \
    ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get install -y \
  build-essential \
  flex \
  git \
  golang \
  libgraphviz-dev \
  locales \
  mc \
  nano

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV GOCACHE=/cache/go/cache
ENV GOPATH=/cache/go

ENV PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ADD init.sh /

CMD ["/bin/bash", "--rcfile", "/init.sh"]
