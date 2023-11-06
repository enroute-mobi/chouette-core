# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :additionnal_path, ''
unless additionnal_path.empty?
  env :PATH, "#{additionnal_path}:#{ENV['PATH']}"
end

env 'DD_TRACE_CONTEXT', "cron"
env 'SENTRY_CONTEXT', "cron"

set :job_template, "/bin/bash -c 'sleep $[$RANDOM % 60] ; :job'"
job_type :rake_if, '[ "$:if" == "true" ] && cd :path && :environment_variable=:environment bundle exec rake :task --silent :output'
job_type :runner,  "cd :path && bundle exec rails runner -e :environment ':task' :output"

every 3.hours do
  rake_if 'cucumber:clean_test_organisations', if: "CHOUETTE_CLEAN_TEST_ORGANISATIONS"
end
