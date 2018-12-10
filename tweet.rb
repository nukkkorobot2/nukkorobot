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
require "mechanize"



#googledrive認証メソッド
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

#深川麻衣のニュース
def hukagawa_news(client)
    url = "http://www.tencarat.co.jp/fukagawamai/"
    #htmlを解析、オブジェクトを作成
    agent = Mechanize.new
    page = agent.get(url)
    news = page.root
    i = 1
    while i < 3
        if news.search("div.content_wrap ul li[#{i}] div.date").inner_text == "#{DateTime.now.year}.#{DateTime.now.month}.#{DateTime.now.day - 1}" && news.search("div.content_wrap ul li[#{i}] div.date").inner_text == "#{DateTime.now.year}.#{DateTime.now.month}.0#{DateTime.now.day-1}"
            text1 = news.search("div.content_wrap ul li[#{i}] h5").inner_text
            text2 = news.search("div.content_wrap ul li[#{i}] p").inner_text
            full_text = "#{text1}" + "\n" + "#{text2}" + "\n" + "#{url}"
            client.update("[深川麻衣]\n#{full_text[0,131]}…")
            if full_text.length > 131 && full_text.length < 270
                client.update("…#{full_text[131,full_text.length]}")
            elsif full_text.length >270
                client.update("…#{full_text[131,268]}…")
                client.update("…#{full_text[269,full_text.length]}")
            end
        end
        i = i + 1
    end
end

#画像保存メソッド
def save_images(client,session,tweet)
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
end

#画像返信メソッド
def reply_images(client,service,session,tweet)
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
end

#天気予報
def weather_forecast(client,tweet)
    #天気用フラグ
    max_flag = 1
    min_flag = 1
    no_weather = 0
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
        elsif tweet.text.include?("青森") || tweet.text.include?("あおもり")
        wcity = "020010"
        city = "青森"
        elsif tweet.text.include?("岩手") || tweet.text.include?("いわて")
        wcity = "030010"
        city = "岩手"
        elsif tweet.text.include?("宮城") || tweet.text.include?("みやぎ")
        wcity = "040010"
        city = "宮城"
        elsif tweet.text.include?("秋田") || tweet.text.include?("あきた")
        wcity = "050010"
        city = "秋田"
        elsif tweet.text.include?("山形") || tweet.text.include?("やまがた")
        wcity = "060010"
        city = "山形"
        elsif tweet.text.include?("福島") || tweet.text.include?("ふくしま")
        wcity = "070010"
        city = "福島"
        elsif tweet.text.include?("茨城") || tweet.text.include?("いばらき")
        wcity = "080010"
        city = "茨城"
        elsif tweet.text.include?("栃木") || tweet.text.include?("とちぎ")
        wcity = "090010"
        city = "栃木"
        elsif tweet.text.include?("群馬") || tweet.text.include?("ぐんま")
        wcity = "100010"
        city = "群馬"
        elsif tweet.text.include?("埼玉") || tweet.text.include?("さいたま")
        wcity = "110010"
        city = "埼玉"
        elsif tweet.text.include?("新潟") || tweet.text.include?("にいがた")
        wcity = "150010"
        city = "新潟"
        elsif tweet.text.include?("富山") || tweet.text.include?("とやま")
        wcity = "160010"
        city = "富山"
        elsif tweet.text.include?("石川") || tweet.text.include?("いしかわ")
        wcity = "170010"
        city = "石川"
        elsif tweet.text.include?("福井") || tweet.text.include?("ふくい")
        wcity = "180010"
        city = "福井"
        elsif tweet.text.include?("山梨") || tweet.text.include?("やまなし")
        wcity = "190010"
        city = "山梨"
        elsif tweet.text.include?("長野") || tweet.text.include?("ながの")
        wcity = "100010"
        city = "長野"
        elsif tweet.text.include?("岐阜") || tweet.text.include?("ぎふ")
        wcity = "210010"
        city = "岐阜"
        elsif tweet.text.include?("静岡") || tweet.text.include?("しずおか")
        wcity = "220010"
        city = "静岡"
        elsif tweet.text.include?("愛知") || tweet.text.include?("あいち")
        wcity = "230010"
        city = "愛知"
        elsif tweet.text.include?("三重") || tweet.text.include?("みえ")
        wcity = "240010"
        city = "三重"
        elsif tweet.text.include?("滋賀") || tweet.text.include?("しが")
        wcity = "250010"
        city = "滋賀"
        elsif tweet.text.include?("京都") || tweet.text.include?("きょうと")
        wcity = "260010"
        city = "京都"
        elsif tweet.text.include?("大阪") || tweet.text.include?("おおさか")
        wcity = "270010"
        city = "大阪"
        elsif tweet.text.include?("兵庫") || tweet.text.include?("ひょうご")
        wcity = "280010"
        city = "兵庫"
        elsif tweet.text.include?("奈良") || tweet.text.include?("なら")
        wcity = "290010"
        city = "奈良"
        elsif tweet.text.include?("和歌山") || tweet.text.include?("わかやま")
        wcity = "300010"
        city = "和歌山"
        elsif tweet.text.include?("鳥取") || tweet.text.include?("とっとり")
        wcity = "310010"
        city = "鳥取"
        elsif tweet.text.include?("島根") || tweet.text.include?("しまね")
        wcity = "320010"
        city = "島根"
        elsif tweet.text.include?("岡山") || tweet.text.include?("おかやま")
        wcity = "330010"
        city = "岡山"
        elsif tweet.text.include?("広島") || tweet.text.include?("ひろしま")
        wcity = "340010"
        city = "広島"
        elsif tweet.text.include?("山口") || tweet.text.include?("やまぐち")
        wcity = "350010"
        city = "山口"
        elsif tweet.text.include?("徳島") || tweet.text.include?("とくしま")
        wcity = "360010"
        city = "徳島"
        elsif tweet.text.include?("香川") || tweet.text.include?("かがわ")
        wcity = "370010"
        city = "香川"
        elsif tweet.text.include?("愛媛") || tweet.text.include?("えひめ")
        wcity = "380010"
        city = "愛媛"
        elsif tweet.text.include?("高知") || tweet.text.include?("こうち")
        wcity = "390010"
        city = "愛媛"
        elsif tweet.text.include?("福岡") || tweet.text.include?("ふくおか")
        wcity = "400010"
        city = "福岡"
        elsif tweet.text.include?("佐賀") || tweet.text.include?("さが")
        wcity = "410010"
        city = "佐賀"
        elsif tweet.text.include?("長崎") || tweet.text.include?("ながさき")
        wcity = "420010"
        city = "長崎"
        elsif tweet.text.include?("熊本") || tweet.text.include?("くまもと")
        wcity = "430010"
        city = "熊本"
        elsif tweet.text.include?("大分") || tweet.text.include?("おおいた")
        wcity = "440010"
        city = "大分"
        elsif tweet.text.include?("宮崎") || tweet.text.include?("みやざき")
        wcity = "450010"
        city = "宮崎"
        elsif tweet.text.include?("鹿児島") || tweet.text.include?("かごしま")
        wcity = "460010"
        city = "鹿児島"
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
        if result['forecasts'][2] != nil
            today_weather = result['forecasts'][2]
            temperature = today_weather['temperature']
            max_temperature = temperature['max']
            min_temperature = temperature['min']
            else
            no_weather = 1
        end
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
    if no_weather == 1
        client.update("@#{tweet.user.screen_name} \n#{city}の明後日の天気予報はまだ出ていません。", in_reply_to_status_id: tweet.id)
    end
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

#休講情報
def kyuko(client,tweet,subjects)
    #スクレイピング先のurl
    ky_url = "http://kyoumu.office.uec.ac.jp/kyuukou/kyuukou.html"
    #webページを開いてhtmlのオブジェクトを作成,代入
    agent = Mechanize.new
    page = agent.get(ky_url)
    doc = page.root
    ky_flag = 0
    ky_counter = 1
    while doc.search("table tr[#{ky_counter}] td[4]").inner_text.empty? == false
        if subjects.any? {|m| doc.search("table tr[#{ky_counter}] td[4]").inner_text.include? m}
            ky_cl = doc.search("table tr[#{ky_counter}] td[1]").inner_text
            ky_date = doc.search("table tr[#{ky_counter}] td[2]").inner_text
            ky_period = doc.search("table tr[#{ky_counter}] td[3]").inner_text
            ky_subject = doc.search("table tr[#{ky_counter}] td[4]").inner_text
            ky_teacher = doc.search("table tr[#{ky_counter}] td[5]").inner_text
            if tweet != nil
                client.update("@#{tweet.user.screen_name}\n[休講情報]\n#{ky_cl}\n#{ky_date}(#{ky_period}時限目)\n#{ky_subject}(#{ky_teacher})", in_reply_to_status_id: tweet.id)
            else
                client.update("[休講情報]\n#{ky_cl}\n#{ky_date}(#{ky_period}時限目)\n#{ky_subject}(#{ky_teacher})")
            end
            ky_flag = 1
        elsif doc.search("table tr[#{ky_counter = ky_counter}] td[1]").inner_text.include?("全科目")
            ky_cl = doc.search("table tr[#{ky_counter = ky_counter}] td[1]").inner_text
            ky_date = doc.search("table tr[#{ky_counter = ky_counter}] td[2]").inner_text
            ky_period = doc.search("table tr[#{ky_counter = ky_counter}] td[3]").inner_text
            ky_subject = doc.search("table tr[#{ky_counter = ky_counter}] td[4]").inner_text
            ky_teacher = doc.search("table tr[#{ky_counter = ky_counter}] td[5]").inner_text
            if tweet != nil
                client.update("@#{tweet.user.screen_name}\n[休講情報]\n#{ky_cl}\n#{ky_date}(#{ky_period}時限目)\n#{ky_subject}(#{ky_teacher})", in_reply_to_status_id: tweet.id)
            else
                client.update("[休講情報]\n#{ky_cl}\n#{ky_date}(#{ky_period}時限目)\n#{ky_subject}(#{ky_teacher})")
            end
            ky_flag = 1
        end
        ky_counter = ky_counter + 1
    end
    if ky_flag == 0 && tweet != nil
        client.update("@#{tweet.user.screen_name}\n現在休講情報は出ていません。",in_reply_to_status_id: tweet.id)
    end
end

#時報ツイート
def time_tweet1(client,now)
    #今日はなんの日
    today_is_url = "https://ja.wikipedia.org/wiki/Template:今日は何の日"
    #htmlを解析、オブジェクトを作成
    agent = Mechanize.new
    page = agent.get(today_is_url)
    today_is = page.root
    today_counter = 1
    while today_is.search("div.mw-parser-output ul li[#{today_counter}]").inner_text.empty? == false
        today_counter = today_counter + 1
    end
    today_counter = rand(today_counter - 1) + 1
    today_text = today_is.search("div.mw-parser-output ul li[#{today_counter}]").inner_text
    client.update("ぬっころBOTが#{now.hour}時ごろをお知らせします。\n。今日、#{now.month}月#{now.day}日は#{today_text}")
    #メモツイート
    if now.hour % 6 == 0
        query = "From:nukkoron #ぬっころメモ"
        client.search(query, count: 10, result_type: "recent",  exclude: "retweets", since_id: nil).take(30).each do |status|
            if status.text.include?("nukkoro_bot")
                client.update("[メモ]\n#{status.text[13,140]}\n##{now.hour}時のリマインド\nhttps://twitter.com/nukkoron/status/#{status.id}")
                else
                client.update("[メモ]\n#{status.text}\n##{now.hour}時のリマインド\nhttps://twitter.com/nukkoron/status/#{status.id}")
            end
        end
    end
end

#TV番組情報取得メソッド
def tv_program(client)
    #スクレイピング先のurl
    t_y = DateTime.now.year
    t_m = DateTime.now.month
    if t_m < 10
        t_m = "0" + "#{t_m}"
    end
    t_d = DateTime.now.day
    if t_d < 10
        t_d = "0" + "#{t_d}"
    end
    tv_url = "https://tv.yahoo.co.jp/search/?q=%E4%B9%83%E6%9C%A8%E5%9D%82&t=1%202%203&a=23&oa=%2B1&d=#{t_y}#{t_m}#{t_d}"
    #htmlを解析、オブジェクトを作成
    agent = Mechanize.new
    page = agent.get(tv_url)
    tv_pr = page.root
    #ページ内を検索、ヒットしたらツイート
    tv_counter = 1
    while tv_counter < 20
        if tv_pr.search("div.mb15 ul.programlist li[#{tv_counter}]").inner_text.empty? == false
            tv_date = tv_pr.search("div.mb15 ul.programlist li[#{tv_counter}] div.leftarea p[1] em").inner_text
            tv_time = tv_pr.search("div.mb15 ul.programlist li[#{tv_counter}] div.leftarea p[2] em").inner_text
            tv_title = tv_pr.search("div.mb15 ul.programlist li[#{tv_counter}] div.rightarea p[1]").inner_text
            tv_comment = tv_pr.search("div.mb15 ul.programlist li[#{tv_counter}] div.rightarea p[3]").inner_text
            tv_ch = tv_pr.search("div.mb15 ul.programlist li[#{tv_counter}] div.rightarea p[2] span.pr35").inner_text
            tv_text = "[テレビ情報]\n#{tv_ch}  #{tv_date} (#{tv_time})\n\n｢#{tv_title}｣\n\n#{tv_comment}"
            if tv_text.length < 141
                client.update(tv_text)
                else
                client.update("#{tv_text[0,139]}…")
                client.update("…#{tv_text[139,279]}")
            end
        end
        tv_counter = tv_counter + 1
    end
end

#家計簿記録メソッド
def kakeibo(client,session,category, money)
    sheet = session.spreadsheet_by_key("1d-qF1P666oAwqrAP1zyqSfc7yk9MvqCQfrGEoM2boN0").worksheets[0]
    category_num = 1
    loop do
        category_num = category_num + 1
        if category[0] == sheet[1,category_num]
            break
        end
        if category_num == 10
            client.update("ERORR:カテゴリが存在しません。\n#{DateTime.now}")
            break
        end
    end
    case category_num
        when 2 then
        col = "B"
        when 4 then
        col = "D"
        when 6 then
        col = "F"
        when 8 then
        col = "H"
        else
        client.update("ERROR:カテゴリが存在しません\n#{DateTime.now}")
    end
    new = 1
    while sheet[new,category_num].empty? == false
        new = new + 1
    end
    sheet[new,category_num - 1] = "#{DateTime.now.year}/#{DateTime.now.month}/#{DateTime.now.day}"
    sheet[new,category_num] = money
    sheet.save
    sheet.reload
    macth_text = "#{DateTime.now.year}\/#{DateTime.now.month}\/*"
    mon_start = 2
    while sheet[mon_start,category_num - 1] !~ /#{macth_text}/
        mon_start = mon_start + 1
    end
    sheet[2,category_num] = "=SUM(#{col}#{mon_start}:#{col}#{new})"
    sheet[2,12] = "=SUM(B2,D2,F2,H2)"
    sheet.save
    sheet.reload
    client.update("[家計簿]\n#{DateTime.now.year}年#{DateTime.now.month}月の出費\n食費:　　#{sheet[2,2]}円\n交際費:　#{sheet[2,4]}円\nクレカ:　#{sheet[2,6]}円\nその他:　#{sheet[2,8]}円\n\n合計:  #{sheet[2,12]}円")
end

#家計簿参照メソッド
def view_kakeibo(client,session)
    sheet = session.spreadsheet_by_key("1d-qF1P666oAwqrAP1zyqSfc7yk9MvqCQfrGEoM2boN0").worksheets[0]
    client.update("[家計簿]\n#{DateTime.now.year}年#{DateTime.now.month}月の出費\n食費:　　#{sheet[2,2]}円\n交際費:　#{sheet[2,4]}円\nクレカ:　#{sheet[2,6]}円\nその他:　#{sheet[2,8]}円\n\n合計:  #{sheet[2,12]}円\n#{DateTime.now}")
end

#メモ記入
def memo(client,session,content)
    sheet = session.spreadsheet_by_key("1oNhzfd8yVd8B8E2adjhZO_qc7KrUzLNHnQdkE3B3FcA").worksheets[0]
    new = 1
    while sheet[new,2].empty? == false
        new = new + 1
    end
    sheet[new,1] = "#{DateTime.now.year}/#{DateTime.now.month}/#{DateTime.now.day}"
    sheet.save
    sheet.reload
    sheet[new,2] = "#{content}"
    sheet.save
    sheet.reload
end

#メモ削除
def rm_memo(session,num)
    sheet = session.spreadsheet_by_key("1oNhzfd8yVd8B8E2adjhZO_qc7KrUzLNHnQdkE3B3FcA").worksheets[0]
    sheet[num+2,1] = ""
    sheet[num+2,2] = ""
    sheet.save
    sheet.reload
end

#メモ表示
def view_memo(client,session)
    sheet = session.spreadsheet_by_key("1oNhzfd8yVd8B8E2adjhZO_qc7KrUzLNHnQdkE3B3FcA").worksheets[0]
    (3..sheet.num_rows).each do |row|
        if sheet[row - 2,2].empty? == false
            client.update("[メモ#{row-2}]\n#{sheet[row,2]}\n\n-Remider at #{DateTime.now.hour}:#{DateTime.now.minute}-")
        end
    end
end


def nogi_news(client)
    url = "http://nogikeyaki46ch.atna.jp/"
    #htmlを解析、オブジェクトを作成
    agent = Mechanize.new
    page = agent.get(url)
    news = page.root
    news.search("div.clearfix table span.item_title_list").inner_text.each do | text |
        client.update("[NEWS]\n#{text}\n\nhttp://nogikeyaki46ch.atna.jp/")
    end
end



#main
begin
    
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
   
    #google API 公式
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
   
    #エゴサ用
    my_name = ["ぬこ", "ぬっころ", "ヌッコロ", "闇猫", "やみ猫", "闇ねこ", "やみねこ"]
    weather_word = ["天気","てんき","気温","きおん"]
   
    #履修科目
    subjects = ["知的財産権","技術者倫理","ハードウェアセキュリティ","ユビキタスネットワーク","デジタル信号処理","コンテンツセキュリティ","ネットワークセキュリティ",
   "暗号理論","データベース論","ソフトウェアセキュリティ","Technical English Intermediate English for Science","歴史学"]
   
    #家計簿カテゴリ
    categories = ["食費","交際費","クレカ","その他"]
   
    #ループカウンタ
    counter = 0
   
    #タイムライン初期位置
    sinceid = client.list_timeline("nukkoro_bot", "tl-list").first.id
   
    #無限ループ
    loop do
        #ツイート読み込み数カウンタ
        i = 0
        #タイムライン読み込み
        client.list_timeline("nukkoro_bot", "tl-list", since_id: sinceid, count: 3).each do |tweet|
            if tweet.user.screen_name != "nukkoro_bot"
                #save_images(client,session,tweet) #画像保存
                #画像を含む場合RT
                media_frag = 0
                tweet.media.each do |media|
                    media_frag = 1
                end
                if media_frag == 1
                    begin
                        client.retweet(tweet.id)
                    rescue Twitter::Error::Forbidden
                        next
                    end
                    
                end
                if tweet.text.include?("美少女") && tweet.text.include?("@nukkoro_bot")
                   reply_images(client,service,session,tweet)
                end
                if weather_word.any? {|m| tweet.text.include? m} && tweet.text.include?("@nukkoro_bot") == true
                   weather_forecast(client,tweet)
                   client.favorite(tweet.id)
                end
                #状態返信
                if tweet.text.include?("@nukkoro_bot") && tweet.text.include?("状態")
                    client.favorite(tweet.id)
                    client.update("@#{tweet.user.screen_name}\nBOTは正常に稼働しています。\n現在#{counter}回目のループです。",in_reply_to_status_id: tweet.id)
                end
                #休講情報
                if tweet.text.include?("nukkoro_bot") && tweet.text.include?("休講")
                    kyuko(client,tweet,subjects)
                end
                #家計簿記録
                if tweet.user.screen_name == "nukkoron" && categories.any? {|m| tweet.text.include? m}
                    money = tweet.text[/([0-9])+/]
                    category = categories.select { |n| tweet.text.include? n}
                    kakeibo(client,session,category, money)
                end
                #メモ記録
                if tweet.user.screen_name == "nukkoron" && tweet.text.include?("#ぬっころメモ")
                    content = tweet.text.delete("#ぬっころメモ")
                    content = content.delete("@nukkoro_bot ")
                    memo(client,session,content)
                    client.favorite(tweet.id)
                end
                #メモ確認
                if tweet.user.screen_name == "nukkoron" && tweet.text.include?("メモ")
                    view_memo(client,session)
                end
                #メモ削除
                if tweet.user.screen_name == "nukkoron" && tweet.text.include?("削除")
                    num = tweet.text[/([0-9])+/]
                    num = num.to_i
                    rm_memo(session,num)
                    client.favorite(tweet.id)
                end
                #エタフォ
                #client.favorite(tweet.id)
            end
            #ツイート読み込み用カウンタが0の時初期位置を更新
            if i == 0
                sinceid = tweet.id unless tweet.retweeted?
            end
            #ツイート読み込み用カウンタ更新
            i = i + 1
        end
        #ループカウンタ更新
        counter = counter + 1
        #bot起動時ツイート
        if counter == 1
            client.update("BOTが再起動しました\n現在#{counter}回目のループです。\n#{DateTime.now}")
        end
        now = DateTime.now
        if now.hour == 23 && now.minute == 30 && now.second >= 0 && now.second <= 3
            view_kakeibo(client,session)
        end
        if now.minute == 0
            if now.second >= 0 && now.second <= 2
                time_tweet1(client,now)
            end
        end
        if now.minute == 15 && now.second >= 0 && now.second <= 2
            #nogi_news(client)
        end
        if now.minute == 30 && now.second >= 0 && now.second <= 2
            view_memo(client,session)
        end
        if now.hour == 0 && now.minute == 0 && now.second >= 0 && now.second <= 5
            kyuko(client,nil,subjects)
            hukagawa_news(client)
            tv_program(client)
        end
        sleep 3
    end
rescue
    client.update("ERROR:300秒待機します。\n[#{DateTime.now}]")
    sleep 300
    retry
end


