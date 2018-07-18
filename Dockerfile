FROM debian:stable-slim

ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true RAILS_LOG_TO_STDOUT=true SIDEKIQ_REDIS_URL=redis://redis:6379/12
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN apt-get update && mkdir -p /usr/share/man/man1 /usr/share/man/man7 && \
    apt-get install -y --no-install-recommends ruby2.3 locales && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen && \
    apt-get install -y --no-install-recommends libpq5 libxml2 zlib1g imagemagick libproj12 postgresql-client-common postgresql-client-9.6 && \
    apt-get install -y --no-install-recommends cron && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    gem2.3 install bundler


COPY stif-boiv-release.tar.gz /
RUN mkdir -p /app/tmp && apt-get update &&\
    apt-get -y install --no-install-recommends build-essential ruby2.3-dev libpq-dev libxml2-dev zlib1g-dev libproj-dev libmagic1 libmagic-dev libmagickwand-dev && \
    tar -C /app -zxf stif-boiv-release.tar.gz && \
    cd /app && bundle install --local && \
    apt-get -y remove build-essential ruby2.3-dev libpq-dev libxml2-dev zlib1g-dev libmagic-dev libmagickwand-dev && \
    apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* && \
    cd /app && rm config/database.yml && mv config/database.yml.docker config/database.yml && \
    cd /app && rm config/secrets.yml && mv config/secrets.yml.docker config/secrets.yml && \
    mv script/launch-cron /app && \
    bundle exec whenever --output '/proc/1/fd/1' --update-crontab chouette --set 'environment=production&bundle_command=bundle exec' --roles=app,db,web

WORKDIR /app
VOLUME /app/public/uploads

EXPOSE 3000

CMD ["sh", "-c", "bundle exec rake db:migrate && bundle exec rails server -b 0.0.0.0"]
