
FROM ubuntu:bionic

MAINTAINER Peter Kleiweg <p.c.j.kleiweg@rug.nl>

RUN apt-get update && apt-get install -y tzdata && \
    echo "Europe/Amsterdam" > /etc/timezone && \
    rm -f /etc/localtime && \
    ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get install -y \
  build-essential \
  flex \
  git \
  libgraphviz-dev \
  locales \
  mc \
  nano

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ADD https://go.dev/dl/go1.22.0.linux-amd64.tar.gz /
RUN cd / && tar vzxf go*tar.gz --no-same-owner && rm go*tar.gz
ENV GOCACHE /cache/go/cache
ENV GOPATH /cache/go

ENV PATH /opt/bin:/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ADD init.sh /

CMD ["/bin/bash", "--rcfile", "/init.sh"]
