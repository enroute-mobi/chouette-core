namespace :ci do
  desc "Prepare CI build"
  task :setup do
    cp "config/database/jenkins.yml", "config/database.yml"
    sh "RAILS_ENV=test rake db:migrate"
    sh "npm --production --no-progress install"
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
    if git_branch == "master"
      "dev"
    elsif git_branch.in?(deploy_envs)
      git_branch
    end
  end

  desc "Check security aspects"
  task :check_security do
    sh "bundle exec bundle-audit check --update"
  end

  task :spec do
    sh "bundle exec rspec --profile"
  end

  task :teaspoon do
    sh "RAILS_ENV=test bundle exec rake teaspoon"
  end

  desc "Deploy after CI"
  task :deploy do
    if deploy_env
      sh "cap #{deploy_env} deploy:migrations"
    else
      puts "No deploy for branch #{git_branch}"
    end
  end

  desc "Clean test files"
  task :clean do
    sh "rm -rf log/test.log"
  end
end

desc "Run continuous integration tasks (spec, ...)"
task :ci => ["ci:setup", "ci:spec", "ci:teaspoon", "cucumber", "ci:check_security", "ci:deploy", "ci:clean"]
