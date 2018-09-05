require "date"
require 'twitter'
require 'net/http'
require 'uri'
require "open-uri"
require "google_drive"


ENV['SSL_CERT_FILE'] = File.expand_path('./cacert.pem')

client = Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV['MY_CONSUMER_KEY']
    config.consumer_secret     = ENV['MY_CONSUMER_SECRET']
    config.access_token        = ENV['MY_ACCESS_TOKEN']
    config.access_token_secret = ENV['MY_ACCESS_TOKEN_SECRET']
end


session = GoogleDrive::Session.from_config("config.json")


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
      client.list_timeline("nukkoro_bot", "tl-list", since_id: sinceid, count: 3).each do |tweet|
          
          
                  puts "--------------------------------------------------"
                  puts "\e[34m#{tweet.user.name}\e[0m \e[32m@#{tweet.user.screen_name}\e[0m"
                  puts "#{tweet.text}"
                  puts "Fav: #{tweet.favorite_count}  RT: #{tweet.retweet_count}"
                  
                  tweet.media.each do |media|
                      name = File.basename(media.media_url)
                      name = "/tmp/" + name
                      open(name, 'wb').write(open(media.media_url).read)
                      rename = tweet.user.name + name
                      session.upload_from_file(name, rename, convert: false)
                      client.update_with_media("#{Time.now}",name)
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
