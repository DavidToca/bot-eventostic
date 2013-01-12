# encoding: UTF-8


require 'rubygems'
require "bundler/setup"
require 'google_calendar'
require 'yaml'
require 'open-uri'
require 'logger'
require 'url_shortener'

require_relative  'twitter_helper'
require_relative  'rss_helper.rb'

class Bot

  CONFIG_FILE = "config.yaml"

  ##
  # initialize the robot with a given config file ( or CONFIG_FILE otherwise)
  #

  def initialize(config_file_name=CONFIG_FILE)

    @logger = Logger.new(STDOUT)


    @config = YAML.load_file(File.join(File.dirname(__FILE__),config_file_name))

    #twitter configuration
    config_twitter = @config['twitter']

    consumer_key = config_twitter['CONSUMER_KEY']
    consumer_secret = config_twitter['CONSUMER_SECRET']
    oauth_token = config_twitter['OAUTH_TOKEN']
    oauth_token_secret = config_twitter['OAUTH_TOKEN_SECRET']

    @twitter = Twitter_helper.new(consumer_key,consumer_secret,oauth_token,oauth_token_secret)


    #google calendar configuration
    config_cal = @config['calendar']

    @cal = Google::Calendar.new(username: config_cal['USERNAME'],
                           password: config_cal['PASSWORD'],
                           calendar: config_cal['CALENDAR_ID'],
                           app_name: config_cal['APP_NAME'])


    config_short = @config['shortener']

    authorize = UrlShortener::Authorize.new config_short['LOGIN'],config_short['API_KEY']

    @shorter_client = UrlShortener::Client.new(authorize)

  end


  ##
  # Updates the calendar with the events in the feeds
  #
  def task_update_calendar


    @logger.debug("#{'*'*5}Executing task update calendar#{'*'*5}")

    events = search_events_in_feeds()

    #adding and getting the added events

    events_added = (events.empty?)? [] : add_events_to_cal(events)

    events_added.each do |event|

      title_max_len = 60

      url = short_url(event.html_link)

      title = ensure_max_length(event.title,title_max_len)

      n = "\u00F1" # n with acent

      message = "se ha a#{n}adido el evento #{title}, mas informacion en #{url} #EventosTICBOG"

      tweet(message)

    end


    @logger.debug("#{'*'*5}Update calendar task executed#{'*'*5}")

    events_added
  end

  ##
  # Tweet events of today and tomorrow
  #
  def task_tweet

    @logger.info("#{'*'*5}Executing tweet task#{'*'*5}")

    #tweet events of today

    @logger.info("Tweet events of today")

    today = Time.now

    events = events_date(today)

    unless events.nil?

      events.each do |event|


      tweet_event(event,today)


     end

    else

       @logger.info("No events found today")

    end


    #tweet tomorrow

    @logger.info("Tweet events of tomorrow")

    tomorrow = add_day(today,1)

    events = events_date(tomorrow)

    unless events.nil?

      events.each do |event|


      tweet_event(event,today)


     end

    else

       @logger.info("No events found tomorrow")

    end


    #tweet avisos parroquiales xD

   # messages = ["Todos los eventos TIC de bogota en google calendar --> http://bit.ly/PXGE9q #EventosTICBOG "]

    #Twitter.update(messages[0])

    # @logger.debug("Tweeting '#{messages[0]}'")


    @logger.info("#{'*'*5}Tweet task executed#{'*'*5}")
  end


  def tweet_event(event, date)

    title_max_len = 45

    same_mon_year = Time.now.month == date.month && Time.now.year == date.year

    same_day = same_mon_year  && Time.now.day == date.day

    tomorrow =  same_mon_year && Time.now.day+1 == date.day


    if same_day

      day = "Hoy"

    elsif tomorrow

      n = "\u00F1" # n with acent

      day = "Ma#{n}ana"

    else

      day = "el #{date.day}/#{date.month}/#{date.year} "

    end

    title_max_len-= day.length


    title = ensure_max_length(event.title,title_max_len)

    url = short_url(event.html_link)

    message = "#{day} a las #{Time.parse(event.start_time).hour} horas se realizara el evento #{title}, mas informacion en #{url} #EventosTICBOG" # /#EventosTICBOG"

    tweet(message)

  end



  private


  ##
  # Tweet a message
  #
  def tweet(message)

    @logger.debug("Tweeting '#{message}'")

    @twitter.tweet(message)

  end

  ##
  # Determines whenever there is already the given event in the calendar
  #
  def in_calendar(event)

    @cal.events.select{|e| e.title == event.title}.length > 0


  end


  ##
  # Makes sure the words dont overcome the max length by cuting the words, and adding three dots if necesary
  #
  def ensure_max_length(words, max_length)
    result = (words.length > max_length) ? (words[0, max_length - 3 ] + "...") : words
  end

  ##
  # Short the given url
  #
  def short_url(url)

    @shorter_client.shorten(url).urls

  end

  ##
  # Add n day(s) to the given date
  #
  def add_day(date,n)


    Time.new(date.year,date.month,date.day+n,date.hour,date.min,date.sec,"-05:00")


  end

  ##
  # Find events of the day of the given date
  #
  def events_date(date)

    start_date = Time.new(date.year,date.month, date.day,0,0,0, "-05:00")

    end_date =  Time.new(date.year,date.month, date.day,23,59,59, "-05:00")

    find_events_in_range(start_date.getutc,end_date.getutc)

  end


  ##
  # Returns an array with all the events in the given range
  #
  def find_events_in_range(start_min,start_max)

    today_events = @cal.find_events_in_range(start_min, start_max)

    #in case it just retriver an event insted of an array, turn it into a array
    if today_events.is_a? Google::Event

      today_events = [today_events]

    end

    return today_events

  end


  ##
  # Search all events in the config feeds
  #
  def search_events_in_feeds

    feeds = @config['feeds']

    response = []

    feeds.each do |rss_feed|

      @logger.debug("Convering entries of #{rss_feed} into events")

      response+= (Rss_helper::fetch_events(rss_feed))

    end

    response

  end

  ##
  # Add all events in the current calendar, if there is some event already in calendar, that event gets omited
  #
  def add_events_to_cal(events)

  events_added = []

  events.each do |evento|

    @logger.info("Adding event\t \"#{evento.title}\"")

    if in_calendar(evento)

      @logger.info("Event\t\t \"#{evento.title}\"\t is already in calendar")

    else

     new_event = @cal.create_event do |e|
      e.title = evento.title
      e.content =  evento.content
      e.start_time = evento.start_time
      e.end_time = evento.end_time

      end

      events_added << new_event

      @logger.info("Event\t\t \"#{evento.title}\"\t\t Added")
    end


   end

   events_added

  end



end






