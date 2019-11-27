#!/bin/sh -e

# Configure UTF-8 locale
apt-get -qq update && apt-get -qq install -y --no-install-recommends locales
export LANG=en_US.UTF-8 LANGUAGE=en_US:UTF-8 LC_ALL=en_US.UTF-8
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
locale

# Prepare yarn package install
apt-get -qq install -y --no-install-recommends curl gnupg ca-certificates apt-transport-https
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo "deb https://deb.nodesource.com/node_8.x stretch main" > /etc/apt/sources.list.d/nodesource.list
apt-get -qq update && apt-get -qq install -y --no-install-recommends yarn nodejs

# Install expected bundler version
gem install "bundler:$BUNDLER_VERSION"

# Install dependencies
export DEV_PACKAGES="build-essential libpq-dev libxml2-dev zlib1g-dev libmagic-dev libmagickwand-dev git-core"
export RUN_PACKAGES="libpq5 libxml2 zlib1g libmagic1 imagemagick libproj-dev libgeos-c1v5 postgresql-client-common postgresql-client-9.6"
mkdir -p /usr/share/man/man1 /usr/share/man/man7
# shellcheck disable=SC2086
apt-get -qq -y install --no-install-recommends $DEV_PACKAGES $RUN_PACKAGES

# Install bundler dependencies
bundle install --quiet --jobs 4 --deployment

# Install yarn dependencies
yarn --frozen-lockfile install

cp config/database.yml.docker config/database.yml
cp config/secrets.yml.docker config/secrets.yml
