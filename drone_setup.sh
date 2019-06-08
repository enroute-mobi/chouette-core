#!/bin/bash

set -eE

LOG_FILE=log/drone_setup.log
trap "cat ${LOG_FILE}" ERR

exec 3>&1 1>>${LOG_FILE} 2>&1

set -x

apt-get -qq update

apt-get -qq install -y --no-install-recommends curl gnupg ca-certificates apt-transport-https

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo "deb https://deb.nodesource.com/node_6.x stretch main" > /etc/apt/sources.list.d/nodesource.list

echo "Install yarn and nodejs" 1>&3

apt-get -qq update
apt-get -qq install -y --no-install-recommends locales yarn nodejs

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

echo "Install bundler $BUNDLER_VERSION" 1>&3
gem install bundler:$BUNDLER_VERSION

DEV_PACKAGES="build-essential ruby2.3-dev libpq-dev libxml2-dev zlib1g-dev libmagic-dev libmagickwand-dev git-core"
RUN_PACKAGES="libpq5 libxml2 zlib1g libmagic1 imagemagick libproj-dev postgresql-client-common postgresql-client-9.6"

mkdir -p /usr/share/man/man1 /usr/share/man/man7

echo "Install dev and run packages : $DEV_PACKAGES $RUN_PACKAGES" 1>&3
apt-get -qq update
apt-get -qq -y install --no-install-recommends $DEV_PACKAGES $RUN_PACKAGES
