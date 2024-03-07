#!/bin/bash

set -e

cd /dbxml
if [ ! -d dbxml2/.git ]
then
    rm -fr dbxml2
    git clone --depth=1 https://github.com/rug-compling/dbxml dbxml2
fi
git config --global --add safe.directory /dbxml/dbxml2
cd dbxml2
git pull

if [ ! -f ../master2 ]
then
    touch ../master2
fi

if diff -q ../master2 .git/refs/heads/master
then
    echo geen veranderingen in DbXML 2
    exit 0
fi

./buildall.sh --prefix=/opt/dbxml2
cp .git/refs/heads/master ../master2


