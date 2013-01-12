require 'rubygems'
require "bundler/setup"
require 'rss'
require 'open-uri'
require 'nokogiri'
require 'google_calendar'
require 'logger'
require 'time'



class Rss_helper

def self.fetch_events(rss_feed)

  logger = Logger.new(STDOUT)

  events = []

# Read the feed into rss_content
open(rss_feed) do |f|
  rss_content = f.read

  # Parse the feed, dumping its contents to rss
  rss = RSS::Parser.parse(rss_content, false)

  rss.items.each do |item|

    event = Google::Event.new

    event.title = item.title

    page = Nokogiri::HTML(item.description)

    paragraphs =  page.css("p")

    #takes all text into text
    text = paragraphs.inject(""){|description,line| description + "\n"+ line}

    event.content = text

    #only take inner_text(without html tags)
    paragraphs = paragraphs.map{|line| line.inner_text}

    #takes the date
    date = self.get_date(paragraphs)

    time = Time.parse(date)

    #if the event month is less than the actual month means it ocurrs the next year

    time = Time.new(time.year+1, time.month,time.day,time.hour  ,time.min,time.sec,'-05:00') if time.month < Time.now.month

    end_time =  Time.new(time.year,time.month,time.day,time.hour + 2 ,time.min,time.sec,'-05:00')

    event.start_time = time

    event.end_time = end_time

    #add the event
    events << event

    end
 end

events

end

def self.valid_date?( str )
  DateTime.strptime(str,'%A, %B %j at %I:%M %p') rescue false
end

def self.get_date(paragraphs)

  paragraphs.reverse.each do |line|
    return line if self.valid_date?(line)

  end

  return nil
end

end





