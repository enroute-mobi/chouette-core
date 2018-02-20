FROM debian:stable-slim

ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true RAILS_LOG_TO_STDOUT=true SIDEKIQ_REDIS_URL=redis://redis:6379/12

RUN apt-get update && \
    apt-get install -y --no-install-recommends ruby2.3 && \
    apt-get install -y --no-install-recommends libpq5 libxml2 zlib1g imagemagick libproj12 && \
    apt-get install -y --no-install-recommends cron && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    gem2.3 install bundler


COPY stif-boiv-release.tar.gz /
RUN mkdir /app && apt-get update &&\
    apt-get -y install --no-install-recommends build-essential ruby2.3-dev libpq-dev libxml2-dev zlib1g-dev libproj-dev libmagic1 libmagic-dev&& \
    tar -C /app -zxf stif-boiv-release.tar.gz && \
    cd /app && bundle install --local && \
    apt-get -y remove build-essential ruby2.3-dev libpq-dev libxml2-dev zlib1g-dev libmagic-dev&& \
    apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* && \
    cd /app && rm config/database.yml && mv config/database.yml.docker config/database.yml && \
    cd /app && rm config/secrets.yml && mv config/secrets.yml.docker config/secrets.yml && \
    mv script/launch-cron /app && \
    bundle exec whenever --output '/proc/1/fd/1' --update-crontab stif-boiv --set 'environment=production&bundle_command=bundle exec' --roles=app,db,web

WORKDIR /app
VOLUME /app/public/uploads

EXPOSE 3000

CMD ["sh", "-c", "bundle exec rake db:migrate && bundle exec rails server -b 0.0.0.0"]
