require 'yaml'

require_relative '../lib/bot'


describe Bot do


  before :all do


    @event_1 = Google::Event.new(title: "event1", content: "content 1", where: "where 1")

    @event_2 = Google::Event.new(title: "event2", content: "content 2", where: "where 2")

    @event_3 = Google::Event.new(title: "event3", content: "content 3", where: "where 3")

    #create the config file

    calendar = {'USERNAME' => 'username@example.com', 'PASSWORD' => 'username password', 'CALENDAR_ID' => '12345', 'APP_NAME' => 'foo app'}

    twitter = {'CONSUMER_KEY' => "foobar123", 'CONSUMER_SECRET' => "barbaz345", 'OAUTH_TOKEN' => '123456789-foo', 'OAUTH_TOKEN_SECRET' => 'foo-bar-123'}

    feeds = ["http://wwww.somefeed.com", "http://www.anotherfeed.com"]

    shortener = {'LOGIN' => 'username', 'API_KEY' => 'foobar123'}

    config = {'calendar' => calendar, 'twitter' => twitter, 'feeds' => feeds, 'shortener' => shortener}

    config_file_name = File.join(File.dirname(__FILE__),"test_config.yaml")

    config_file = File.open(config_file_name, "w") do |out|

      YAML::dump(config,out)

    end

    @url_file = config_file.path


  end

  before :each do

    @twitter_mock = double("twitter")

    @twitter_mock.stub(:tweet)

    @cal_mock = double("google calendar")

    @cal_mock.stub(:events).and_return([])

    @cal_mock.should_receive(:create_event).and_return(@event_1,@event_2,@event_3)

    @shortener_mock = double("shortener")

    @shortener_response_mock = double("shortener response")

    @shortener_response_mock.stub(:urls).and_return("http://bit.ly/ZUutS0")

    @shortener_mock.stub(:shorten).and_return(@shortener_response_mock)

    @rss_mock = double("rss")

    UrlShortener::Client.stub(:new).and_return(@shortener_mock)

    Twitter_helper.should_receive(:new).and_return(@twitter_mock)

    Google::Calendar.should_receive(:new).and_return(@cal_mock)

    UrlShortener::Client.should_receive(:new).and_return(@shortener_mock)

    Rss_helper.should_receive(:fetch_events).and_return([@event_1,@event_2],[@event_3])

    @bot = Bot.new(@url_file)

  end


  after :all do

    File.delete(@url_file)

  end
=begin
  describe "#new" do

    it "takes no parameters and return a Bot object" do


      new_event = @cal_mock.create_event do |e|

        e.title = "asdf"

      end

#      @event_2.should eql new_event

      @bot.should be_an_instance_of Bot

    end

  end
=end

  describe "#task_update_calendar" do

    it "update the calendar with the feed info" do

      @bot.task_update_calendar.should eql [@event_1,@event_2,@event_3]

    end

  end

end





