require 'capistrano/ext/multistage'
require './config/boot'

set :stages, %w(sandbox dev staging production)
set :application, "stif-boiv"
set :scm, :git
set :repository,  "git@github.com:AF83/stif-boiv.git"
set :deploy_to, "/var/www/stif-boiv"
set :use_sudo, false
set :ruby_version, "2.3.0"
default_run_options[:pty] = true
set :group_writable, true
set :bundle_cmd, "/var/lib/gems/#{ruby_version}/bin/bundle"
set :rake, "#{bundle_cmd} exec rake"
set :default_environment, {
  'PATH' => "/var/lib/gems/#{ruby_version}/bin:$PATH",
  'NODE_ENV' => "production"
}

set :keep_releases, -> { fetch(:kept_releases, 5) }
after "deploy:restart", "deploy:cleanup"

set :rails_env, -> { fetch(:stage) }
set :deploy_via, :remote_cache
set :copy_exclude, [ '.git' ]
ssh_options[:forward_agent] = true

require "bundler/capistrano"
require 'whenever/capistrano'

#require 'capistrano/npm'
#set :npm_options, '--production --no-progress'

#after 'deploy:finalize_update', 'npm:install'

# Whenever
set :whenever_variables, ->{ "'environment=#{fetch :whenever_environment}&bundle_command=bin/bundle exec&additionnal_path=/var/lib/gems/#{ruby_version}/bin'" } # invoke bin/bundle to use 'correct' ruby environment

set :whenever_command, "sudo /usr/local/sbin/whenever-sudo" # use sudo to change www-data crontab
set :whenever_user, "www-data" # use www-data crontab

set :whenever_output, "2>&1 | logger -t stif-boiv/cron"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

 # Prevent errors when chmod isn't allowed by server
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, releases_path, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "mkdir -p #{dirs.join(' ')} && (chmod g+w #{dirs.join(' ')} || true)"
  end

  task :bundle_link do
    run "mkdir -p #{release_path}/bin && ln -fs #{bundle_cmd} #{release_path}/bin/bundle"
  end
  after "bundle:install", "deploy:bundle_link"

  desc "Run yarn install"
  task :yarn do
    run "cd #{release_path} && yarn --production --no-progress install"
  end
  after "bundle:install", "deploy:yarn"

  desc "Symlinks shared configs and folders on each release"
  task :symlink_shared, :except => { :no_release => true }  do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/"
    run "ln -nfs #{shared_path}/config/environments/#{rails_env}.rb #{release_path}/config/environments/"
    run "ln -nfs #{shared_path}/config/secrets.yml #{release_path}/config/"
    run "ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/"

    run "rm -rf #{release_path}/public/uploads"
    run "ln -nfs #{shared_path}/public/uploads #{release_path}/public/uploads"
    run "ln -nfs #{shared_path}/tmp/uploads #{release_path}/tmp/uploads"
    run "ln -nfs #{shared_path}/tmp/imports #{release_path}/tmp/imports"
  end
  after 'deploy:update_code', 'deploy:symlink_shared'
  before 'deploy:assets:precompile', 'deploy:symlink_shared'
  after 'deploy:assets:precompile', "deploy:i18n_js_export"

  desc "Make group writable all deployed files"
  task :group_writable do
    run "sudo /usr/local/sbin/cap-fix-permissions #{deploy_to}"
  end
  after "deploy:restart", "deploy:group_writable"

  desc "Restart sidekiq"
  task :sidekiq_restart do
    run "sudo sidekiq-touch #{fetch(:application)}"
  end
  after "deploy:restart", "deploy:sidekiq_restart"

  desc "Run i18n:js:export"
  task :i18n_js_export do
    run "cd #{release_path} && RAILS_ENV=#{rails_env} #{rake} i18n:js:export"
  end

  desc "Run db:seed"
  task :seed do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} #{rake} db:seed"
  end
end
