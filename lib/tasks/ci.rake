namespace :ci do

  def database_name
    @database_name ||=
      begin
        config = YAML.load(ERB.new(File.read('config/database.yml')).result)
        config["test"]["database"]
      end
  end

  def parallel_tests?
    ENV["PARALLEL_TESTS"] == "true"
  end

  desc "Prepare CI build"
  task :setup do
    unless ENV["IGNORE_YARN_INSTALL"]
      # FIXME remove this specific behavior
      # Managed by Dockerfile.build
      sh "yarn --frozen-lockfile install"
    end

    unless ENV["KEEP_DATABASE_CONFIG"]
      # FIXME remove this specific behavior
      cp "config/database.yml", "config/database.yml.orig"
      cp "config/database/ci.yml", "config/database.yml"
    end

    puts "Use #{database_name} database"
    if parallel_tests?
      sh "RAILS_ENV=test rake parallel:drop parallel:create parallel:migrate"
    else
      sh "RAILS_ENV=test rake db:drop db:create db:migrate"
    end
  end

  task :fix_webpacker do
    # Redefine webpacker:yarn_install to avoid --production
    # in CI process
    Rake::Task["webpacker:yarn_install"].clear
    Rake::Task.define_task "webpacker:yarn_install" do
      puts "Don't run yarn"
    end
  end

  def git_branch
    if ENV['GIT_BRANCH'] =~ %r{/(.*)$}
      $1
    else
      `git rev-parse --abbrev-ref HEAD`.strip
    end
  end

  def deploy_envs
    Dir["config/deploy/*.rb"].map { |f| File.basename(f, ".rb") }
  end

  def deploy_env
    return ENV["DEPLOY_ENV"] if ENV["DEPLOY_ENV"]
    if git_branch == "master"
      "dev"
    elsif git_branch.in?(deploy_envs)
      git_branch
    end
  end

  desc "Check security aspects"
  task :check_security do
    unless ENV["CI_CHECKSECURITY_DISABLED"]
      command = "bundle exec bundle-audit check --update"
      ignoring_lapse = 1.month
      if File.exists? '.bundle-audit-ignore'
        ignored = []
        File.open('.bundle-audit-ignore').each_line do |line|
          id, date = line.split('#').map(&:strip)
          date = date.to_date
          puts "Found vulnerability #{id}, ignored until #{date + ignoring_lapse}"
          if date > ignoring_lapse.ago
            ignored << id
          end
        end
        command += " --ignore #{ignored.join(' ')}" if ignored.present?
      end
      sh command
    end
  end

  task :add_temporary_security_check_ignore, [:id] do |t, args|
    `echo "#{args[:id]} # #{Time.now}" >> .bundle-audit-ignore`
  end

  task :assets do
    sh "RAILS_ENV=test bundle exec rake ci:fix_webpacker assets:precompile i18n:js:export"
  end

  task :jest do
    sh "node_modules/.bin/jest" unless ENV["CHOUETTE_JEST_DISABLED"]
  end

  desc "Deploy after CI"
  task :deploy do
    unless ENV["CHOUETTE_DEPLOY_DISABLED"]
      if deploy_env
        sh "cap #{deploy_env} deploy:migrations deploy:seed"
      else
        puts "No deploy for branch #{git_branch}"
      end
    end
  end

  desc "Clean test files"
  task :clean do
    sh "rm -rf log/test.log"
    sh "RAILS_ENV=test bundle exec rake assets:clobber"
  end

  task :spec do
    if parallel_tests?
      # parallel tasks invokes this task ..
      # but development db isn't available during ci tasks
      Rake::Task["db:abort_if_pending_migrations"].clear

      Rake::Task["parallel:spec"].invoke
    else
      Rake::Task["spec"].invoke
    end
  end

  task :build => ["ci:setup", "ci:assets", "ci:spec", "ci:jest", "cucumber", "ci:check_security"]

  namespace :docker do
    task :clean do
      puts "Drop #{database_name} database"
      if parallel_tests?
        sh "RAILS_ENV=test rake parallel:drop"
      else
        sh "RAILS_ENV=test rake db:drop"
      end

      # Restore projet config/database.yml
      # cp "config/database.yml.orig", "config/database.yml" if File.exists?("config/database.yml.orig")
    end
  end

  task :docker => ["ci:build"]
end

desc "Run continuous integration tasks (spec, ...)"
task :ci => ["ci:build", "ci:deploy", "ci:clean"]
