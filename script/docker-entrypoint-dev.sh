#!/bin/bash -x

command=${1:-front}

mkdir -p "$HOME"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

function setup {
    bundle install --jobs 8 --path vendor/bundle
    yarn install
    bundle exec rake db:create db:migrate
    bundle exec rake db:seed
}

echo "Start $command"
case $command in
  async)
    export RUBY_GC_HEAP_GROWTH_FACTOR=1.1
    exec bundle exec mwrap ./script/delayed-job-worker
    ;;
  front)
    if [ "$RUN_SETUP" = "true" ]; then
      setup || exit $?
    fi

    rm -f tmp/pids/server.pid
    exec bundle exec rails server -b 0.0.0.0
    ;;
  shell)
    exec bash
    ;;
  console)
    exec bundle exec rails console
    ;;
  migrate)
    exec bundle exec rake db:migrate
    ;;
  tests)
      bundle exec rake parallel:create parallel:migrate
      exec bundle exec parallel_test spec -t rspec --runtime-log log/parallel_runtime_specs.log --test-options '--format progress --fail-fast'
    ;;
  bundle)
    shift
    exec bundle $@
    ;;
  rake)
    shift
    exec bundle exec rake $@
    ;;
  rails)
    shift
    exec bundle exec rails $@
    ;;
  setup)
    ;;
  seed)
    exec bundle exec rake db:seed
    ;;
  *)
    exec $@
esac
