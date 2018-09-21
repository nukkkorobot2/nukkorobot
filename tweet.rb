require "date"
require 'twitter'
require 'net/http'
require 'uri'
require "open-uri"
require "google_drive"
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'nokogiri'


ENV['SSL_CERT_FILE'] = File.expand_path('./cacert.pem')

client = Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV['MY_CONSUMER_KEY']
    config.consumer_secret     = ENV['MY_CONSUMER_SECRET']
    config.access_token        = ENV['MY_ACCESS_TOKEN']
    config.access_token_secret = ENV['MY_ACCESS_TOKEN_SECRET']
end

#google API 非公式
session = GoogleDrive::Session.from_config("config.json")

#google API 公式情報
OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Drive API Ruby Quickstart'.freeze
CREDENTIALS_PATH = 'credentials.json'.freeze
TOKEN_PATH = 'token.yaml'.freeze
SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY


def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
        url = authorizer.get_authorization_url(base_url: OOB_URI)
        puts 'Open the following URL in the browser and enter the ' \
        "resulting code after authorization:\n" + url
        code = gets
        credentials = authorizer.get_and_store_credentials_from_code(
                                                                     user_id: user_id, code: code, base_url: OOB_URI
                                                                     )
    end
    credentials
end


#google API 公式
service = Google::Apis::DriveV3::DriveService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize


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

#履修科目
subjects = ["知的財産権","技術者倫理","ハードウェアセキュリティ","ユビキタスネットワーク","デジタル信号処理","コンテンツセキュリティ","ネットワークセキュリティ",
            "暗号理論","データベース論","ソフトウェアセキュリティ","Technical English Intermediate English for Science"]


#カウンタ
counter = 0
save_flag = 0

#BOT起動ツイート
client.update("BOT起動\n(#{DateTime.now})")
client.update("起動中...\n(#{DateTime.now})")
client.update("起動完了\n(#{DateTime.now})")



#タイムライン初期位置
sinceid = client.list_timeline("nukkoro_bot", "test").first.id
loop do
  
      #ツイート読み込み数カウンタ
      i = 0
      #タイムライン読み込み
      client.list_timeline("nukkoro_bot", "tl-list", since_id: sinceid, count: 3).each do |tweet|
          
          
          
          
          if tweet.user.screen_name != "nukkoro_bot"
              
              
                  #フラグ
                  save_flag = 0
              
                  #画像保存ブロック
                  tweet.media.each do |media|
                      name = File.basename(media.media_url)
                      name = "/tmp/" + name
                      open(name, 'wb').write(open(media.media_url).read)
                      rename = tweet.user.name + name
                      #ドライブにアップロード
                      session.upload_from_file(name, rename, convert: false)
                      #save_flag
                      save_flag = 1
                  end
                  
                  if save_flag == 1
                      client.retweet(tweet.id)
                  end
                  
                  #画像返信ブロック
                  if tweet.text.include?("美少女") && tweet.text.include?("@nukkoro_bot")
                      pictures = []
                      
                      #最新200件取得
                      response = service.list_files(page_size: 200,
                                                    fields: 'nextPageToken, files(id, name)')
                                                    
                      response.files.each do |file|
                            pictures << file.name
                      end
                      
                      picture = session.file_by_title(pictures[rand(pictures.length)])
                      
                      picture.download_to_file("/tmp/test.jpg")
                      
                      client.update_with_media("@#{tweet.user.screen_name} ","/tmp/test.jpg", in_reply_to_status_id: tweet.id)
                  end
                  
                  
                  
                  
                  #天気用フラグ
                  max_flag = 1
                  min_flag = 1
                  
                  #天気予報ブロック
                  if weather_word.any? {|m| tweet.text.include? m} && tweet.text.include?("@nukkoro_bot") == true
                      
                      #検索都市分岐
                      #都市一覧=>http://weather.livedoor.com/forecast/rss/primary_area.xml
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
                  
                  
                  #状態返信
                  if tweet.text.include?("@nukkoro_bot") && tweet.text.include?("状態")
                      client.update("@#{tweet.user.screen_name}\nBOTは正常に稼働しています。\n現在#{counter}回目のループです。",in_reply_to_status_id: tweet.id)
                  end
                  
                  #休講情報返信
                  if tweet.text.include?("nukkoro_bot") && tweet.text.include?("休講")
                      
                      #スクレイピング先のurl
                      ky_url = "http://kyoumu.office.uec.ac.jp/kyuukou/kyuukou.html"
                      
                      #webページを開いてhtmlに返す
                      charset = nil
                      html = open(ky_url, 'r:Shift_JIS') do |page|
                          page.read
                      end
                      
                      #htmlを解析してオブジェクトを作成
                      doc = Nokogiri::HTML.parse(html, nil)
                      
                      ky_flag = 0
                      ky_counter = 1
                      while doc.search("table tr[#{i}] td[4]").inner_text.empty? == false
                          if subjects.any? {|m| doc.search("table tr[#{i}] td[4]").inner_text.include? m}
                              ky_cl = doc.search("table tr[#{i}] td[1]").inner_text
                              ky_date = doc.search("table tr[#{i}] td[2]").inner_text
                              ky_period = doc.search("table tr[#{i}] td[3]").inner_text
                              ky_subject = doc.search("table tr[#{i}] td[4]").inner_text
                              ky_teacher = doc.search("table tr[#{i}] td[5]").inner_text
                              client.update("@#{tweet.user.screen_name}\n[休講情報]\n#{ky_cl}\n#{ky_date}(#{ky_period}時限目)\n#{ky_subject}(#{ky_teacher})", in_reply_to_status_id: tweet.id)
                              ky_flag = 1
                          end
                          ky_counter = ky_counter + 1
                      end
                      
                      if ky_flag == 0
                          client.update("@#{tweet.user.screen_name}\n現在休講情報は出ていません。",in_reply_to_status_id: tweet.id)
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
       end
    #ループカウンタ更新
    counter = counter + 1
    
    #ループカウンタが2000の倍数でツイート
    if counter % 1000 == 0 || counter == 1
        client.update("現在#{counter}回目のループです。\n#{DateTime.now}")
    end
    
    
    #時報
    now = DateTime.now
    if now.minute == 0
        if now.second >= 0 && now.second <= 5
            if now.hour >= 15
                client.update("ぬっころBOTが#{now.hour-15}時ごろをお知らせします。")
                else
                client.update("ぬっころBOTが#{now.hour+9}時ごろをお知らせします。")
            end
            
        end
    end
    
    
    
    #休講情報取得
    if now.hour == 15 && now.minute == 0 && now.second >= 0 && now.second <= 5
        #スクレイピング先のurl
        ky_url = "http://kyoumu.office.uec.ac.jp/kyuukou/kyuukou.html"
        
        #webページを開いてhtmlに返す
        charset = nil
        html = open(ky_url, 'r:Shift_JIS') do |page|
            page.read
        end
        
        #htmlを解析してオブジェクトを作成
        doc = Nokogiri::HTML.parse(html, nil)
        
        ky_flag = 0
        ky_counter = 1
        while doc.search("table tr[#{i}] td[4]").inner_text.empty? == false
            if subjects.any? {|m| doc.search("table tr[#{i}] td[4]").inner_text.include? m}
                ky_cl = doc.search("table tr[#{i}] td[1]").inner_text
                ky_date = doc.search("table tr[#{i}] td[2]").inner_text
                ky_period = doc.search("table tr[#{i}] td[3]").inner_text
                ky_subject = doc.search("table tr[#{i}] td[4]").inner_text
                ky_teacher = doc.search("table tr[#{i}] td[5]").inner_text
                client.update("[休講情報]\n#{ky_cl}\n#{ky_date}(#{ky_period}時限目)\n#{ky_subject}(#{ky_teacher})")
                ky_flag = 1
            end
            ky_counter = ky_counter + 1
        end
        
        if ky_flag == 0
            client.update("現在休講情報は出ていません。")
        end
    end
    
    
    
    #３秒待機
    sleep 3
    
    
    
end
