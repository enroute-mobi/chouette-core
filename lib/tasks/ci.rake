namespace :ci do

  def cache_files
    @cache_files ||= []
  end

  def cache_file(name)
    cache_files << name
  end

  def parallel_tests?
    ENV["PARALLEL_TESTS"] == "true"
  end

  def use_schema?
    ENV["USE_SCHEMA"] == "true"
  end

  def quiet?
    ENV["QUIET"] == "true"
  end

  desc "Prepare CI build"
  task :setup do
    if parallel_tests?
      command = use_schema? ? "parallel:setup" : "parallel:create parallel:migrate"
      sh "RAILS_ENV=test rake #{command}"
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

  desc "Check security aspects"
  task :check_security do
    unless ENV["CI_CHECKSECURITY_DISABLED"]
      command = "bundle exec bundle-audit check --update"
      ignoring_lapse = 1.month
      if File.exists? '.bundle-audit-ignore'
        ignored = []
        File.open('.bundle-audit-ignore').each_line do |line|
          next unless line.present?
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

  task :spec do
    if parallel_tests?
      # parallel tasks invokes this task ..
      # but development db isn't available during ci tasks
      Rake::Task["db:abort_if_pending_migrations"].clear

      parallel_specs_command = "parallel_test spec -t rspec"

      runtime_log = "log/parallel_runtime_specs.log"
      parallel_specs_command += " --runtime-log #{runtime_log}" if File.exists? runtime_log

      # Add test options
      test_options = "--format ParallelTests::RSpec::RuntimeLogger --out #{runtime_log}"
      summary_log = "log/summary_specs.log"
      test_options += " --format ParallelTests::RSpec::SummaryLogger --out #{summary_log}"

      unless quiet?
        test_options += " --format progress"
      end

      parallel_specs_command += " --test-options '#{test_options}'"

      begin
        sh parallel_specs_command
      ensure
        sh "cat #{runtime_log} | grep '^spec' | sort -t: -k2 -n -r -" if File.exists?(runtime_log)
        sh "cat #{summary_log}" if File.exists?(summary_log)
        # Dir["log/*_specs.log"].sort.each do |spec_log_file|
        #   sh "cat #{spec_log_file}"
        # end
      end
    else
      Rake::Task["spec"].invoke
    end
  end
  cache_file "log/parallel_runtime_specs.log"

  task :build => ["ci:setup", "ci:assets", "ci:spec", "ci:jest", "ci:check_security"]

  namespace :docker do
    task :clean do
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

  namespace :cache do

    def cache_dir
      "cache"
    end

    def cache_dir?
      Dir.exists? cache_dir
    end

    def store_file(file)
      return unless cache_dir?
      cp file, cache_dir if File.exists?(file)
    end

    def fetch_file(file)
      return unless cache_dir?
      cache_file = File.join(cache_dir, File.basename(file))
      cp cache_file, file if File.exists?(cache_file)
    end

    # Retrive usefull data from cache at the beginning of the build
    task :fetch do
      cache_files.each do |cache_file|
        puts "Retrieve #{cache_file} from cache"
        fetch_file cache_file
      end
    end

    # Fill cache at the end of the build
    task :store do
      cache_files.each do |cache_file|
        puts "Store #{cache_file} in cache"
        store_file cache_file
      end
    end
  end
end

desc "Run continuous integration tasks (spec, ...)"
task :ci => ["ci:cache:fetch", "ci:build", "ci:cache:store"]
