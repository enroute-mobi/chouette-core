namespace :ci do
  def parallel_tests?
    ENV["PARALLEL_TESTS"] == "true"
  end

  def use_schema?
    ENV["USE_SCHEMA"] != "false"
  end

  def quiet?
    ENV["QUIET"] == "true"
  end

  def fail_fast?
    ENV["FAIL_FAST"] == "true"
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
    unless ENV["CHOUETTE_JEST_DISABLED"]
      sh "PATH=node_modules/.bin:$PATH jest --coverage"
    end
  end

  def test_options(xml_output: "rspec")
    test_options = ""

    unless xml_output == :none
      test_options += "--format RspecJunitFormatter --out test-results/#{xml_output}.xml"
    end

    if fail_fast?
      test_options += " --fail-fast"
    end

    unless quiet?
      test_options += " --format progress"
    end

    test_options
  end

  task :spec do
    if parallel_tests?
      # parallel tasks invokes this task ..
      # but development db isn't available during ci tasks
      Rake::Task["db:abort_if_pending_migrations"].clear

      parallel_specs_command = "parallel_test spec -t rspec"

      runtime_log = 'parallel_tests/runtime.log'

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

      parallel_specs_command += ' --runtime-log cache/runtime.log' if File.exist? 'cache/runtime.log'

      parallel_test_options = '-r spec_helper '
      parallel_test_options += test_options(xml_output: 'parallel-tests<%= ENV["TEST_ENV_NUMBER"] %>')

      parallel_test_options += " --format ParallelTests::RSpec::RuntimeLogger --out #{runtime_log}"

      summary_log = "log/summary_specs.log"
      parallel_test_options += " --format ParallelTests::RSpec::SummaryLogger --out #{summary_log}"

      # We're using .rspec_parallel to provide an unique file to each parallel test process
      File.write ".rspec_parallel", parallel_test_options

      begin
        sh parallel_specs_command
      ensure
        sh "cat #{runtime_log} | grep '^spec' | sort -t: -k2 -n -r -" if File.exist?(runtime_log)
        sh "cat #{summary_log}" if File.exist?(summary_log)
      end
    else
      sh "bundle exec rspec #{test_options()}"
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

  task :performance do
    sh "bundle exec rspec --tag performance #{test_options(xml_output: 'performance')}"
  end
end
