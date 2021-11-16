#!/bin/bash

command=${1:-front}

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ -n "$GCLOUD_KEYFILE_JSON" ]; then
    echo -En "$GCLOUD_KEYFILE_JSON" > "config/storage-key.json"
    unset GCLOUD_KEYFILE_JSON
fi

echo "Start $command"
case $command in
  async)
    export RUBY_GC_HEAP_GROWTH_FACTOR=1.1
    exec bundle exec ./script/delayed-job-worker
    ;;
  sync)
    exec ./script/launch-cron
    ;;
  front)
    if [ "$RUN_MIGRATIONS" = "true" ]; then
      bundle exec rake db:migrate || exit $?
    fi
    if [ "$RUN_SEED" = "true" ]; then
      bundle exec rake db:seed || exit $?
    fi
    rm -rf tmp/pids/ && mkdir -p tmp/pids
    exec bundle exec rails server -b 0.0.0.0
    ;;
  shell)
    exec bash
    ;;
  console)
    exec bundle exec rails console production
    ;;
  migrate)
    exec bundle exec rake db:migrate
    ;;
  seed)
    exec bundle exec rake db:seed
    ;;
  migrate-and-seed)
    bundle exec rake db:migrate && bundle exec rake db:seed
    ;;
  *)
    exec $@
esac
