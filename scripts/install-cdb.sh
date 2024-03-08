#!/bin/bash

set -e

rm -f /build/cdb.dact /build/cdb.dact.tmp

cd /tmp
/opt/bin/dbxml_create /build/cdb.dact.tmp *.xml
cd /build
mv cdb.dact.tmp cdb.dact
