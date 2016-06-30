
FROM debian:8

MAINTAINER Peter Kleiweg <p.c.j.kleiweg@rug.nl>

RUN apt-get update && apt-get install -y \
  ca-certificates \
  curl \
  flex \
  g++ \
  git \
  libgraphviz-dev \
  libtk8.5 \
  locales \
  make \
  nano

RUN sed -e 's/^# en_US.UTF-8'/en_US.UTF-8'/' /etc/locale.gen > /etc/locale.gen.tmp && \
    mv /etc/locale.gen.tmp /etc/locale.gen && \
    locale-gen

ENV PATH /mod/paqu/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PAQU /mod/data

RUN cd /usr/local && \
    curl -s https://storage.googleapis.com/golang/go1.6.2.linux-amd64.tar.gz | tar vxzf - && \
    cd go && rm -r api blog doc misc test

# Downloading the index triggers a new download of sources when anything in the index has changed
ADD http://www.let.rug.nl/alfa/docker/paqu/ /index
RUN rm /index && mkdir -p /mod && cd /mod && \
    curl -s http://www.let.rug.nl/alfa/docker/paqu/alpino.tar.gz | tar vxzf - && \
    curl -s http://www.let.rug.nl/alfa/docker/paqu/corpora.tar.gz | tar vxzf - && \
    curl -s http://www.let.rug.nl/alfa/docker/paqu/dbxml.tar.gz | tar vxzf -

ADD https://github.com/rug-compling/paqu/commits/master.atom /master
RUN cd /mod && git clone https://github.com/rug-compling/paqu && rm /master

RUN echo OPTS = -v                          > /mod/paqu/src/Makefile.cfg && \
    echo export GOPATH=/mod/paqu/_vendor    >> /mod/paqu/src/Makefile.cfg && \
    echo export CPATH=/mod/dbxml/include    >> /mod/paqu/src/Makefile.cfg && \
    echo export LIBRARY_PATH=/mod/dbxml/lib >> /mod/paqu/src/Makefile.cfg
RUN make -C /mod/paqu/src all

ADD corpustest.go /mod/tools/                                                                                     
ADD dbwait.go /mod/tools/                                                                                     
ADD init.sh /mod/etc/                                                                                     
ADD entrypoint.sh /mod/etc

EXPOSE 9000

ENTRYPOINT ["/mod/etc/entrypoint.sh"]
CMD ["run"]
