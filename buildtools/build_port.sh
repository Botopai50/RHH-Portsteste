#!/bin/bash

# Shared build driver for RHH-Ports buildtools/
# Usage: ./build_port.sh <portdir>
# where <portdir> is e.g. buildtools/sonic-mania/sonic-mania

HOSTROOT=`pwd`
DOCKERROOT=/root

PORTDIR=$1
PORTNAME=`basename $PORTDIR`
SRCDIR=$PORTDIR/src
SETUPSCRIPT=$SRCDIR/docker-setup.txt
PRODUCTSCRIPT=$SRCDIR/retrieve-products.txt
BUILDSCRIPT=$SRCDIR/build.txt

BUILDDIR=build-port

mkdir -p $HOSTROOT/$BUILDDIR
cd $HOSTROOT/$BUILDDIR
cp $HOSTROOT/$SRCDIR/* .

bash $HOSTROOT/$SETUPSCRIPT $PORTNAME-build

sleep 5

docker exec $PORTNAME-build /bin/bash -c "cd $BUILDDIR && bash $DOCKERROOT/$BUILDSCRIPT"

bash $HOSTROOT/$PRODUCTSCRIPT $HOSTROOT/$BUILDDIR $HOSTROOT/$PORTDIR
