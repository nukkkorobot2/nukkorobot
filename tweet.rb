require "date"
require 'twitter'
require 'net/http'
require 'uri'
require "open-uri"
require 'fastimage'


client = Twitter::REST::Client.new do |config|
    config.consumer_key = '5S3U0xfDIWqnD9uR0gYXFc4t9'
    config.consumer_secret = 'AIysfbrDyadcuNVJ4USRwLiwhq5ZY4AjBhOICik8MnMeLs2GjK'
    config.access_token = '909615085147975682-AapiikOAwUDEROEhFcntUyySf8v1i7r'
    config.access_token_secret = 'i6LdK8psuZA1KAz7lGzM4RMk4VRH8DCZvbqXnscQA1YEl'
end

#キューの定義
class Array
    alias_method :enqueue, :push
    alias_method :dequeue, :shift
end

#短縮URL展開関数
def expand_url(url)
    begin
        response = Net::HTTP.get_response(URI.parse(url))
        rescue
        return url
    end
    case response
        when Net::HTTPRedirection
        expand_url(response['location'])
        else
        url
    end
end



#画像保存関数



#エゴサ用
my_name = ["ぬこ", "ぬっころ", "ヌッコロ", "闇猫", "やみ猫", "闇ねこ", "やみねこ"]

#
#タイムライン読み込み
#

sinceid = client.list_timeline("nukkoro_bot", "test").first.id
loop do
  
      i = 0
      client.list_timeline("nukkoron", "tl-20180814181253", since_id: sinceid, count: 3).each do |tweet|
                  puts "--------------------------------------------------"
                  puts "\e[34m#{tweet.user.name}\e[0m \e[32m@#{tweet.user.screen_name}\e[0m"
                  puts "#{tweet.text}"
                  #if tweet.text.include?("https") == true
                  #   url = tweet.text[/https:\/\/t.co\/(.+?){10}/]
                  #   real_url = expand_url(url)
                  #   if real_url.include?("photo") == true && tweet.user.screen_name != "nukkoro_bot"
                  #       client.update(tweet.text)
                  #   end
                  #end
                  puts "Fav: #{tweet.favorite_count}  RT: #{tweet.retweet_count}"
                  if my_name.any? {|m| tweet.text.include? m} && tweet.text.include?("@nukkoron") == false
                      client.favorite(tweet.id)
                  end
                  if tweet.text.include?("@nukkoron") && tweet.text.include?("占い")
                      random_tweet = ["うるせーーーーーー！！\n知らねーーーーーー！！\n\n     🤴\n     👊╋━━━━\n         OCHINPO\n              CARNIVAL",
                                      "今日のあなたの股間は曇りのち雨。土砂災害に注意して",
                                      "うんこ漏れるうううううううううううう(´･_･`)",
                                      "大吉"]
                      
                      client.update("@#{tweet.user.screen_name} \n#{random_tweet[rand(random_tweet.length)]}", in_reply_to_status_id: tweet.id)
                  end
                  if i == 0
                      sinceid = tweet.id unless tweet.retweeted?
                  end
                  i = i + 1
                  #client.favorite(tweet.id)
       end
    
    #３秒待機
    sleep 3
end
