#!/usr/bin/env rake
require File.expand_path('../config/application', __FILE__)
ChouetteIhm::Application.load_tasks

%w{seed create drop}.each do |task|
  Rake::Task["apartment:#{task}"].clear
  Rake::Task.define_task "apartment:#{task}" do
    puts "Task apartment:#{task} is disabled"
  end
end
