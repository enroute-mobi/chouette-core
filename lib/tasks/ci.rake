# frozen_string_literal: true

namespace :ci do
  def parallel_tests?
    ENV['PARALLEL_TESTS'] == 'true'
  end

  def use_schema?
    ENV['USE_SCHEMA'] != 'false'
  end

  def quiet?
    ENV['QUIET'] != 'false'
  end

  def fail_fast?
    ENV['FAIL_FAST'] == 'true'
  end

  desc 'Prepare CI build'
  task setup: :environment do
    if parallel_tests?
      command = use_schema? ? 'parallel:setup' : 'parallel:create parallel:migrate'
      redirect = ' > /dev/null' if quiet?
      sh "RAILS_ENV=test rake #{command}#{redirect}"
    else
      sh 'RAILS_ENV=test rake db:drop db:create db:migrate'
    end
  end

  task disable_yarn_install: :environment do
    # Redefine yarn:install to avoid --production
    # in CI process
    Rake::Task['yarn:install'].clear
    Rake::Task.define_task 'yarn:install' do
      puts "Don't run yarn"
    end
  end

  desc 'Check security aspects'
  task check_security: :environment do
    unless ENV['CI_CHECKSECURITY_DISABLED']
      command = 'bundle exec bundle-audit check --update'
      ignoring_lapse = 1.month
      if File.exist? '.bundle-audit-ignore'
        ignored = []
        File.open('.bundle-audit-ignore').each_line do |line|
          next if line.blank?

          id, date = line.split('#').map(&:strip)
          date = date.to_date
          puts "Found vulnerability #{id}, ignored until #{date + ignoring_lapse}"
          ignored << id if date > ignoring_lapse.ago
        end
        command += " --ignore #{ignored.join(' ')}" if ignored.present?
      end
      sh command
    end
  end

  task :add_temporary_security_check_ignore, [:id] => :environment do |_t, args|
    `echo "#{args[:id]} # #{Time.zone.now}" >> .bundle-audit-ignore`
  end

  task assets: :environment do
    sh 'RAILS_ENV=test bundle exec i18n export'
    sh 'RAILS_ENV=test NODE_OPTIONS=--openssl-legacy-provider bundle exec rake ci:disable_yarn_install assets:precompile'
  end

  task jest: :environment do
    sh 'PATH=node_modules/.bin:$PATH jest --coverage' unless ENV['CHOUETTE_JEST_DISABLED']
  end

  def test_options(xml_output: 'rspec')
    test_options = ''

    test_options += "--format RspecJunitFormatter --out test-results/#{xml_output}.xml" unless xml_output == :none

    test_options += ' --fail-fast' if fail_fast?

    test_options += ' --format progress' unless quiet?

    test_options
  end

  task spec: :environment do
    if parallel_tests?
      # parallel tasks invokes this task ..
      # but development db isn't available during ci tasks
      Rake::Task['db:abort_if_pending_migrations'].clear

      parallel_specs_command = 'parallel_test spec -t rspec'

      runtime_log = ENV.fetch('PARALLEL_RUNTIME_LOG', 'parallel_tests/runtime.log')

      if ENV['BITBUCKET_PARALLEL_STEP_COUNT']
        step_count = ENV['BITBUCKET_PARALLEL_STEP_COUNT'].to_i
        step = ENV['BITBUCKET_PARALLEL_STEP'].to_i

        runtime_log = "parallel_tests/runtime-#{step}.log"

        cpu_count =
          if ENV['PARALLEL_TEST_PROCESSORS']
            ENV['PARALLEL_TEST_PROCESSORS'].to_i
          else
            ParallelTests.determine_number_of_processes(nil)
          end

        group_count = cpu_count * step_count
        group_selection = Range.new(step * cpu_count, (step + 1) * cpu_count, true).to_a

        parallel_specs_command += " -n #{group_count} --only-group #{group_selection.join(',')}"
      end

      read_runtime_log = ENV.fetch('PARALLEL_RUNTIME_LOG', 'cache/runtime.log')
      parallel_specs_command += " --runtime-log #{read_runtime_log}" if File.exist?(read_runtime_log)

      parallel_test_options = '-r spec_helper '
      parallel_test_options += test_options(xml_output: 'parallel-tests<%= ENV["TEST_ENV_NUMBER"] %>')

      parallel_test_options += " --format ParallelTests::RSpec::RuntimeLogger --out #{runtime_log}"

      summary_log = 'log/summary_specs.log'
      parallel_test_options += " --format ParallelTests::RSpec::SummaryLogger --out #{summary_log}"

      # We're using .rspec_parallel to provide an unique file to each parallel test process
      File.write '.rspec_parallel', parallel_test_options

      begin
        sh parallel_specs_command
      ensure
        unless quiet?
          sh "cat #{runtime_log} | grep '^spec' | sort -t: -k2 -n -r -" if File.exist?(runtime_log)
          sh "cat #{summary_log}" if File.exist?(summary_log)
        end
      end
    else
      sh "bundle exec rspec #{test_options}"
    end
  end

  # def codacy_coverage(language,file)
  #   if File.exist?(file)
  #     codacy_coverage_reporter "report -l #{language} -r #{file}"
  #   end
  # end

  # task :codacy do
  #   if ENV['CODACY_PROJECT_TOKEN']
  #     codacy_coverage :ruby, "coverage/coverage.xml"
  #     codacy_coverage :javascript, "coverage/lcov.info"
  #   end
  # end

  task performance: :environment do
    sh "bundle exec rspec --tag performance #{test_options(xml_output: 'performance')}"
  end
end
