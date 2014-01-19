#!/usr/bin/env rake

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.ruby_opts = ["-r./spec/spec_helper"]
  t.pattern = "spec/**/*_spec.rb"
end

namespace :test do
  desc "Test tasks locally"
  task :tasks do
    require 'crew'
    home = Crew::Home.new(File.expand_path("..", __FILE__))
    task_count = 0
    total_passes, total_failures = 0, 0
    untested_tasks_count = 0

    home.each_task do |task|
      puts "Testing #{task.name}"
      task_count += 1
      passes, failures = home.test(task.name)
      if passes + failures == 0
        untested_tasks_count += 1
      else
        total_passes += passes
        total_failures += failures
      end
    end
    puts "Total tasks: #{task_count}"
    puts "Total untested tasks: #{untested_tasks_count}"
  end
end
