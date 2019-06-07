#!/bin/sh

set -ex
apt-get update

apt-get install -y --no-install-recommends curl gnupg ca-certificates apt-transport-https

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo "deb https://deb.nodesource.com/node_6.x stretch main" > /etc/apt/sources.list.d/nodesource.list
apt-get update && apt-get install -y --no-install-recommends locales yarn nodejs

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
gem install bundler:$BUNDLER_VERSION

DEV_PACKAGES="build-essential ruby2.3-dev libpq-dev libxml2-dev zlib1g-dev libmagic-dev libmagickwand-dev git-core"
RUN_PACKAGES="libpq5 libxml2 zlib1g libmagic1 imagemagick libproj-dev postgresql-client-common postgresql-client-9.6"

mkdir -p /usr/share/man/man1 /usr/share/man/man7

apt-get update
apt-get -y install --no-install-recommends $DEV_PACKAGES $RUN_PACKAGES
