
require 'thread'

require_relative 'bot'

#seconds * minutes * hours

TIME_BETWEEN_TASK = 60 * 60 * 4

bot = Bot.new

process = Thread.new do

while(true)

  #execute tasks

  #update calendar /w feeds info

  bot.task_update_calendar


  #tweet
  bot.task_tweet


  sleep(TIME_BETWEEN_TASK)



end


end

process.join








