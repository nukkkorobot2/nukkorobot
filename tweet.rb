require 'twitter'
ENV['SSL_CERT_FILE'] = File.expand_path('./cacert.pem')


client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['MY_CONSUMER_KEY']
  config.consumer_secret     = ENV['MY_CONSUMER_SECRET']
  config.access_token        = ENV['MY_ACCESS_TOKEN']
  config.access_token_secret = ENV['MY_ACCESS_TOKEN_SECRET']
end

stream_client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = ENV['MY_CONSUMER_KEY']
  config.consumer_secret     = ENV['MY_CONSUMER_SECRET']
  config.access_token        = ENV['MY_ACCESS_TOKEN']
  config.access_token_secret = ENV['MY_ACCESS_TOKEN_SECRET']
end

stream_client.user do |tweet|
  if tweet.is_a?(Twitter::Tweet)
    client.update("@#{tweet.user.screen_name}\ntest", options = {:in_reply_to_status_id => tweet.id})
    client.favorite(tweet.id)
    client.retweet(tweet.id)
  end
end