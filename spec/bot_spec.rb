require 'yaml'

require_relative '../lib/bot'


describe Bot do



  before :all do



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

  after :all do

    File.delete(@url_file)

  end


  before :each do


    @event_1 = Google::Event.new(title: "event1", content: "content 1", where: "where 1")

    @event_2 = Google::Event.new(title: "event2", content: "content 2", where: "where 2")

    @event_3 = Google::Event.new(title: "event3", content: "content 3", where: "where 3")

    @twitter_mock = mock("twitter", tweet: nil)

    @cal_mock = mock("google calendar",events: [] )

    @cal_mock.should_receive(:create_event).and_return(@event_1,@event_2,@event_3)

    @shortener_mock = mock("shortener", shorten: stub( urls: "http://bit.ly/ZUutS0"))

    @rss_mock = mock("rss")

    UrlShortener::Client.stub(:new).and_return(@shortener_mock)

    Google::Calendar.stub(:new).and_return(@cal_mock)

    Twitter_helper.stub(:new).and_return(@twitter_mock)

    UrlShortener::Client.stub(:new).and_return(@shortener_mock)

    Rss_helper.stub(:fetch_events).and_return([@event_1,@event_2],[@event_3])

#    @bot = Bot.new(@url_file)

  end

  describe "#task_update_calendar" do

    subject{ Bot.new(@url_file) }

    it "update the calendar with the feed info" do

      subject.task_update_calendar.should eql [@event_1,@event_2,@event_3]

    end

  end

end













