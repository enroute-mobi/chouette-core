#!/bin/sh

command=${1:-front}

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "Start $command"
case $command in
  async)
    rm -rf tmp/pids/ && mkdir -p tmp/pids
    exec bundle exec sidekiq -e production
    ;;
  async2)
    exec bundle exec rake jobs:work
    ;;
  sync)
    exec bash ./script/launch-cron
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
  *)
    exec $@
esac
