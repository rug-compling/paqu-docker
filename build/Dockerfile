#
# PaQu in Docker
#
# To build and push to repository:
#
#     docker build -t registry.webhosting.rug.nl/compling/paqu:latest .
#     docker push registry.webhosting.rug.nl/compling/paqu:latest
#

FROM ubuntu:bionic

MAINTAINER Peter Kleiweg <p.c.j.kleiweg@rug.nl>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates \
  curl \
  flex \
  g++ \
  git \
  golang-1.13-go \
  less \
  libcurl4 \
  libgraphviz-dev \
  libtk8.6 \
  locales \
  make \
  nano \
  python3-minimal \
  vim

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV PATH /mod/paqu/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/mod/Alpino/bin:/mod/Alpino/Tokenization:/usr/lib/go-1.13/bin
ENV PAQU /mod/data
ENV ALPINO_HOME /mod/Alpino

# Downloading the index triggers a new download of sources when anything in the index has changed
ADD http://www.let.rug.nl/alfa/docker/paqu/ /index
RUN rm /index && mkdir -p /mod && cd /mod && \
    curl -s http://www.let.rug.nl/alfa/docker/paqu/alpino.tar.gz | tar vxzf - && \
    curl -s http://www.let.rug.nl/alfa/docker/paqu/corpora.tar.gz | tar vxzf - && \
    curl -s http://www.let.rug.nl/alfa/docker/paqu/dbxml.tar.gz | tar vxzf -

ADD https://github.com/rug-compling/paqu/commits/master.atom /master
RUN cd /mod && git clone https://github.com/rug-compling/paqu && rm /master

# Add libraries to standard path
RUN ldconfig /mod/dbxml/lib /mod/Alpino/boost

RUN echo OPTS = -v                                                      > /mod/paqu/src/Makefile.cfg && \
    echo GO = go                                                       >> /mod/paqu/src/Makefile.cfg && \
    echo export CGO_CFLAGS=-I/mod/dbxml/include                        >> /mod/paqu/src/Makefile.cfg && \
    echo export CGO_CXXFLAGS=-I/mod/dbxml/include                      >> /mod/paqu/src/Makefile.cfg && \
    echo export CGO_LDFLAGS=-L/mod/dbxml/lib -Wl,-rpath=/mod/dbxml/lib >> /mod/paqu/src/Makefile.cfg

RUN make -C /mod/paqu/src all

ADD corpustest.go /mod/tools/
ADD dbtest.go /mod/tools/
ADD dbwait.go /mod/tools/
ADD init.sh /mod/etc/
ADD entrypoint.sh /mod/etc
RUN chmod 555 /mod/etc/entrypoint.sh && \
    cd /mod/tools && \
    cp /mod/paqu/go.* . \
    go build -o corpustest corpustest.go && \
    go build -o dbtest dbtest.go && \
    go build -o dbwait dbwait.go

ENV LD_LIBRARY_PATH=/mod/Alpino/create_bin/extralibs/boost

EXPOSE 9000

ENTRYPOINT ["/mod/etc/entrypoint.sh"]
CMD ["run"]

ADD cdbdate /mod/corpora
ADD cdbversion /mod/corpora
