# encoding: UTF-8

require 'rubygems'
require "bundler/setup"
require 'twitter'


##
# helper class
#
class Twitter_helper


  ##
  # Initialize an object with oauth parameters
  #
  def initialize(params)

    consumer_key = params['CONSUMER_KEY']
    consumer_secret = params['CONSUMER_SECRET']
    oauth_token = params['OAUTH_TOKEN']
    oauth_token_secret = params['OAUTH_TOKEN_SECRET']


     Twitter.configure do |config|
      config.consumer_key = consumer_key
      config.consumer_secret = consumer_secret
      config.oauth_token = oauth_token
      config.oauth_token_secret = oauth_token_secret
     end

  end


  ##
  # tweet a message
  #
  def tweet(message)

      Twitter.update(message.encode("UTF-8"))

  end


end




















