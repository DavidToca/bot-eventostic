require 'rubygems'
require 'rake'
require 'echoe'
require_relative 'lib/bot'

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }

task default: [:run]

desc "run a thread that runs all tasks"
task :run do
  ruby "lib/run.rb"
end

desc "tweet upcoming events"
task :tweet do

  bot = Bot.new
  bot.task_tweet

end

desc "update the calendar with entries of feeds"
task :update_calendar do

  bot = Bot.new
  bot.task_update_calendar

end



