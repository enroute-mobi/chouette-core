# Usage
#
# docker build -t chouette-core-drone -f Dockerfile.drone .
# docker tag chouette-core-drone:latest enroute/chouette-core-drone:latest
# docker push enroute/chouette-core-drone:latest

FROM ruby:2.6-slim

ENV RAILS_ENV "test"
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV BUNDLER_VERSION "2.0.1"
ENV DEV_PACKAGES "build-essential ruby2.3-dev libpq-dev libxml2-dev zlib1g-dev libmagic-dev libmagickwand-dev git-core"
ENV RUN_PACKAGES "libpq5 libxml2 zlib1g libmagic1 imagemagick libproj-dev libgeos-c1v5 postgresql-client-common postgresql-client-9.6"

WORKDIR /drone

COPY drone_setup.sh ./
RUN ./drone_setup.sh
