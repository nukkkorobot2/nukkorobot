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
weather_word = ["天気","てんき","気温","きおん"]


#ループカウンタ
counter = 0


#タイムライン初期位置
sinceid = client.list_timeline("nukkoro_bot", "test").first.id
loop do
  
      #ツイート読み込み数カウンタ
      i = 0
      #タイムライン読み込み
      client.list_timeline("nukkoro_bot", "tl-list", since_id: sinceid, count: 3).each do |tweet|
          
                  #画像保存ブロック
                  tweet.media.each do |media|
                      name = File.basename(media.media_url)
                      name = "/tmp/" + name
                      open(name, 'wb').write(open(media.media_url).read)
                      rename = tweet.user.name + name
                      #ドライブにアップロード
                      session.upload_from_file(name, rename, convert: false)
                      #ツイッターに完了ツイート
                      client.update_with_media("save complete",name)
                  end
                  
                  
                  #天気用フラグ
                  max_flag = 1
                  min_flag = 1
                  
                  #天気予報ブロック
                  if weather_word.any? {|m| tweet.text.include? m} && tweet.text.include?("@nukkoron") == true
                      
                      #検索都市分岐
                      if tweet.text.include?("東京")
                          wcity = "130010"
                          city = "東京"
                          elsif tweet.text.include?("横浜") || tweet.text.include?("神奈川")
                          wcity = "140010"
                          city = "横浜"
                          elsif tweet.text.include?("千葉")
                          wcity = "120010"
                          city = "千葉"
                          elsif tweet.text.include?("沖縄") || tweet.text.include?("那覇")
                          wcity = "471010"
                          city = "沖縄"
                          elsif tweet.text.include?("札幌") || tweet.text.include?("北海道")
                          wcity = "016010"
                          city = "札幌"
                          else
                          wcity = "130010"
                          city = "東京"
                      end
                      
                      #天気情報取得
                      uri = URI.parse("http://weather.livedoor.com/forecast/webservice/json/v1?city=#{wcity}")
                      json = Net::HTTP.get(uri)
                      result = JSON.parse(json)
                      
                      #日にち分岐
                      if tweet.text.include?("明日") || tweet.text.include?("あした")
                          today_weather = result['forecasts'][1]
                          temperature = today_weather['temperature']
                          max_temperature = temperature['max']
                          min_temperature = temperature['min']
                          elsif tweet.text.include?("明後日") || tweet.text.include?("あさって") || tweet.text.include?("明日の明日")
                          today_weather = result['forecasts'][2]
                          temperature = today_weather['temperature']
                          max_temperature = temperature['max']
                          min_temperature = temperature['min']
                          else
                          today_weather = result['forecasts'][0]
                          temperature = today_weather['temperature']
                          max_temperature = temperature['max']
                          min_temperature = temperature['min']
                      end
                      
                      if max_temperature == nil
                          max_flag = 0
                      end
                      if min_temperature == nil
                          min_flag = 0
                      end
                      
                      #天気予報をリプライで返信
                      if max_flag == 1 && min_flag == 1
                          client.update("@#{tweet.user.screen_name} \n#{city}の#{today_weather['dateLabel']}の天気は#{today_weather['telop']}\n最高気温:#{max_temperature['celsius']}℃\n最低気温:#{min_temperature['celsius']}℃", in_reply_to_status_id: tweet.id)
                          elsif max_flag == 1 && min_flag == 0
                          client.update("@#{tweet.user.screen_name} \n#{city}の#{today_weather['dateLabel']}の天気は#{today_weather['telop']}\n最高気温:#{max_temperature['celsius']}℃\n最低気温:no data", in_reply_to_status_id: tweet.id)
                          elsif max_flag == 0 && min_flag == 1
                          client.update("@#{tweet.user.screen_name} \n#{city}の#{today_weather['dateLabel']}の天気は#{today_weather['telop']}\n最高気温:no data\n最低気温:#{min_temperature['celsius']}℃", in_reply_to_status_id: tweet.id)
                          else
                          client.update("@#{tweet.user.screen_name} \n#{city}の#{today_weather['dateLabel']}の天気は#{today_weather['telop']}\n最高気温:no data\n最低気温:no data", in_reply_to_status_id: tweet.id)
                      end
                  end
                  
                  
                  #ツイート読み込み用カウンタが0の時初期位置を更新
                  if i == 0
                      sinceid = tweet.id unless tweet.retweeted?
                  end
                  #ツイート読み込み用カウンタ更新
                  i = i + 1
                  
                  
                  #エタフォ
                  client.favorite(tweet.id)
       end
    #ループカウンタ更新
    counter = counter + 1
    
    #ループカウンタが2000の倍数でツイート
    if counter % 2000 == 0
        client.update("現在#{counter}回目のループです。")
    end
    
    #３秒待機
    sleep 3
end
