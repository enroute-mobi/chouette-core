#!/usr/bin/env rake
require_relative 'config/application'
Rails.application.load_tasks

%w{seed create drop}.each do |task|
  Rake::Task["apartment:#{task}"].clear
  Rake::Task.define_task "apartment:#{task}" do
    puts "Task apartment:#{task} is disabled"
  end
end
