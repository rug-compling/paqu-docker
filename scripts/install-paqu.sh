#!/bin/bash

set -e

cd /paqu
if [ ! -d paqu/.git ]
then
    rm -fr paqu
    git clone --depth=1 https://github.com/rug-compling/paqu
fi

git config --global --add safe.directory /paqu/paqu
cd paqu
git pull

if [ ! -f ../master ]
then
    touch ../master
fi

if diff -q ../master .git/refs/heads/master
then
    echo geen veranderingenin PaQu
    exit 0
fi

cd src

cat <<EOT > Makefile.cfg
OPTS = -v
GO = go
export CGO_CFLAGS=-I/opt/dbxml2/include
export CGO_CXXFLAGS=-I/opt/dbxml2/include
export CGO_LDFLAGS=-L/opt/dbxml2/lib -Wl,-rpath=/opt/dbxml2/lib
EOT

cp internal/dir/default.go.example internal/dir/default.go

make all

mkdir -p /opt/bin
mv ../bin/* /opt/bin

cd /paqu
cp paqu/.git/refs/heads/master master
