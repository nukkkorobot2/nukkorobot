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
    tweet_url = "https://twitter.com/#{tweet.user.id}/status/#{tweet.id}"
    client.favorite(tweet.id)
    if tweet.user.screen_name == "beauty_master_1"
      client.retweet(tweet.id)
      client.update("@nukkoron \n 新しい投稿です\n #{tweet_url}")
    end 
  end
end

stream_client.user do |followers|
    if followers.is_a?(Twitter::followers)
        client.update("#{followers.screen_name}さんフォローありがとうございます")
        client.follow(followers.screen_name)
    end
end

