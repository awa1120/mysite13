require "bundler/setup"
Bundler.require
require './src/web/ip002/SearchConditions' #他クラスをrequire（import）する際は./が必要

if development?
  require 'sinatra/reloader'
end

logger = Logger.new('sinatra.log')
SearchConditions = SearchConditions.new

client = PG::connect(
  :host => ENV.fetch("DB_HOST","localhost"),
  :user => ENV.fetch("DB_USER"),
  :password => ENV.fetch("DB_PASSWORD"),
  :dbname => ENV.fetch("DB_NAME")
)

enable :sessions

#ログインエラーフラグ
@error_flag = 0

#ログイン画面
get '/login' do
  # :layout => nilの指定で、レイアウトファイルを使用しないことが可能。
  #エラーフラグをパラメタ領域に格納
  @error_flag = session[:error_flag]
  return erb :login, :layout => nil
end

post '/signin' do
 email = params[:email]
 password = params[:password]
 user = client.exec_params("SELECT * FROM users WHERE email = '#{email}' AND password = '#{password}'").to_a.first
if user.nil?
  # return erb :login
  session[:error_flag] = 1
  return redirect '/login'
else
  session[:error_flag] = 0
  session[:user] = user
  session[:employee_id] = user
  session[:authority] = user
  return redirect '/index'
 end
end

#トップメニュー
get "/index" do
    @name = session[:user]['name'] # 書き換える
    @employee_id = session[:employee_id]['employee_id'] # 書き換える

    #予算額合計（年間）取得処理-----------------------------------------------
    yosan_total = client.exec_params("select sum(差引額) from yosan where 予算コード='A1001' and 処理区分='0';").to_a
    logger.info yosan_total
    # 数値を3桁区切りにする。
    yosan_total_A = yosan_total[0]["sum"]
    @yosan_total = yosan_total_A.to_s.gsub(/(\d)(?=\d{3}+$)/, '\\1,')

    #費用合計（年間）取得処理-------------------------------------------------
    hiyou_total = client.exec_params("select sum(差引額) from yosan where 予算コード='A1001' and 処理区分!='0';").to_a
    hiyou_total_A = hiyou_total[0]["sum"]
    @hiyou_total = hiyou_total_A.to_s.gsub(/(\d)(?=\d{3}+$)/, '\\1,').delete("-")

    #予算消化率-------------------------------------------------------------
    yosan_total_B = yosan_total_A.to_i
    hiyou_total_B = hiyou_total_A.to_i.abs
    # 小数点が必要な計算はquoと.tofを使用する。
    @yosan_syokaritsu = (hiyou_total_B.quo(yosan_total_B)).to_f * 100

    #申請件数取得処置-------------------------------------------------------------
    shinsei_kensu = client.exec_params("select count(*) from shinsei where 予算コード='A1001' and 取消区分='0';").to_a
    @shinsei_kensu = shinsei_kensu[0]["count"]

    # 折れ線グラフ用予算取得処理----------------------------------------------
    yosan_chart1 = client.exec_params("select SUBSTRING(差引日,1,6) as 年月,差引額 from yosan where 予算コード='A1001'").to_a
    logger.info yosan_chart1

    # chart用の変数を定義する。
    @month_4 = 0
    @month_5 = 0
    @month_6 = 0
    @month_7 = 0
    @month_8 = 0
    @month_9 = 0
    @month_10 = 0
    @month_11 = 0
    @month_12 = 0
    @month_1 = 0
    @month_2 = 0
    @month_3 = 0
  
    yosan_chart1.each do |x|
      logger.info x['年月']
      case x['年月']
      #決め打ちで2021年度とする。時間があれば申請データに年度の概念を持たせることとしたい。
      when "202104" then
        @month_4 += x['差引額'].to_i
      when "202105" then
        @month_5 += x['差引額'].to_i
      when "202106" then
        @month_6 += x['差引額'].to_i
      when "202107" then
        @month_7 += x['差引額'].to_i
      when "202108" then
        @month_8 += x['差引額'].to_i
      when "202109" then
        @month_9 += x['差引額'].to_i
      when "202110" then
        @month_10 += x['差引額'].to_i
      when "202111" then
        @month_11 += x['差引額'].to_i
      when "202112" then
        @month_12 += x['差引額'].to_i
      when "202201" then
        @month_1 += x['差引額'].to_i
      when "202202" then
        @month_2 += x['差引額'].to_i
      when "202203" then
        @month_3 += x['差引額'].to_i
      end
    end
    logger.info @month_4
    return erb :index
end

#費用申請コントローラエリア
get '/ip001A' do
  # :layout => nilの指定で、レイアウトファイルを使用しないことが可能。
  @name = session[:user]['name'] # 書き換える
  @employee_id = session[:employee_id]['employee_id'] # 書き換える
  @authority = session[:authority] #権限情報を渡す。
  @shinsei_zhokyo = "未申請"
  @gamen_param = 0 #メニューから遷移
  return erb :ip001A
end

#インサート用メソッド
post '/ip001A_insert' do
  #画面で入力した値をparamsから取り出す。
  @dete = [
    shinseisya_id= params[:shinseisya],
    shinseibi= params[:shinseibi].delete("/"),
    hiyoubi= params[:hiyoubi].delete("/"),
    hiyou_kubun= params[:hiyou_kubun],
    kenmei= params[:kenmei],
    syosai= params[:syosai],
    yosan_code= params[:yosan_code],
    zeikomi= params[:zeikomi],
    zeinuki= params[:zeinuki],
    zeigaku= params[:zeigaku],
    bikou= params[:bikou]]
    logger.info shinseibi

  #画面から取得できない項目を登録
  shinsei_zyokyo = "1"
  zeiritsu = 10
  tenpu_file =""
  torikeshi_kubun ="0"

  #添付ファイルを取得
  if !params[:img].nil? # データがあれば処理を続行する
    tempfile = params[:img][:tempfile] # ファイルがアップロードされた場所
    save_to = "./public/tmp/#{params[:img][:filename]}" # ファイルを保存したい場所
    tenpu_file = "./tmp/#{params[:img][:filename]}" # DBに登録する。
    FileUtils.mv(tempfile, save_to)
    @img_name = params[:img][:filename]
  end

  #【01_申請DB更新処理】 
  insert_sql_01 = "INSERT INTO shinsei (申請者ID,申請日,費用発生日,費用区分,件名,詳細,予算コード,税込額,税抜額,税額,税率,備考,申請状況,添付ファイル,取消区分)"
  insert_sql_02 = "VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)"
  insert_sql_03 = [shinseisya_id,shinseibi,hiyoubi,hiyou_kubun,kenmei,syosai,yosan_code,zeikomi,zeinuki,zeigaku,zeiritsu,bikou,shinsei_zyokyo,tenpu_file,torikeshi_kubun]
  
  # cliantインスタンスでSQL詰め込み
  client.exec_params("#{insert_sql_01} #{insert_sql_02}",insert_sql_03);
  shinsei_no_array = []
  shinsei_no_array =  client.exec_params("select id from shinsei ORDER BY id DESC LIMIT 1;").to_a
  logger.info shinsei_no_array
  # 配列の中のハッシュは以下のとおりの処理で取得が可能である。
  logger.info shinsei_no_array[0]["id"]

  #【11_予算DB更新処理】 
  #予算差引処理
  sashihiki = zeikomi.to_i - (zeikomi.to_i * 2)
  syori_kubun ="1"
  kakutei_kubun = "0"
  shinsei_no = shinsei_no_array[0]["id"]

  insert_sql_11 = "INSERT INTO yosan (予算コード,差引日,差引額,申請者id,申請id,費用区分,処理区分,確定区分,取消区分)"
  insert_sql_12 = "VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)"
  insert_sql_13 = [yosan_code,hiyoubi,sashihiki,shinseisya_id,shinsei_no[0],hiyou_kubun,syori_kubun,kakutei_kubun,torikeshi_kubun]
  client.exec_params("#{insert_sql_11} #{insert_sql_12}",insert_sql_13);

  #【21_承認DB更新処理】 
  insert_sql_21 = "INSERT INTO syonin (申請番号,承認日,承認者id,承認コメント,取消区分)"
  insert_sql_22 = "VALUES ($1,$2,$3,$4,$5)"
  insert_sql_23 = [shinsei_no,'','','','']
  client.exec_params("#{insert_sql_21} #{insert_sql_22}",insert_sql_23);

  @message = "申請が完了しました。申請データは「申請検索」から確認できます。"
  return erb :temporary
end

#予算登録コントローラエリア
get '/ip031A' do
  # :layout => nilの指定で、レイアウトファイルを使用しないことが可能。
  @name = session[:user]['name'] # 書き換える
  @employee_id = session[:employee_id]['employee_id'] # 書き換える
  return erb :ip031A
end

#インサート用メソッド
post '/ip031A_insert' do
  #画面で入力した値をparamsから取り出す。
  @dete = [
    yosan_code= params[:yosan_code],
    yosan_haitoubi= params[:yosan_haitoubi].delete("/"),
    yosan_haitougaku= params[:yosan_haitougaku].to_i]

    #予算差引処理
    shinseisya_id ="0"
    shinsei_no = 0
    hiyou_kubun = "0"
    syori_kubun ="0"
    torikeshi_kubun ="0"
    kakutei_kubun = "1"

  # cliantインスタンスでSQL詰め込み
  client.exec_params("INSERT INTO yosan (予算コード,差引日,差引額,申請者id,申請id,費用区分,処理区分,確定区分,取消区分) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)",
  [yosan_code,yosan_haitoubi,yosan_haitougaku,shinseisya_id,shinsei_no,hiyou_kubun,syori_kubun,kakutei_kubun,torikeshi_kubun]);
  @message = "予算登録が完了しました。"
  return erb :temporary
end


get '/ip002A' do
  @select_data =[]
  @name = session[:user]['name'] # 書き換える
  @employee_id = session[:employee_id]['employee_id'] # 書き換える
  @authority = session[:user]['authority'] #権限情報を渡す。
  return erb :ip002A
end

post '/ip002A_select_js' do
  logger.info "SinatraPost"
  #検索用クラスのインスタンスを呼び出す。
  sql = SearchConditions.Conditions(
  shinseibi_s: params[:shinseibi1_s].delete("/"),
  shinseibi_e: params[:shinseibi1_e].delete("/"),
  hiyoubi_s: params[:hiyoubi2_s].delete("/"),
  hiyoubi_e: params[:hiyoubi2_e].delete("/"),
  shinseisya: params[:shinseisya3],
  kenmei: params[:kenmei4],
  syosai: params[:syosai5])

  @select_data =  client.exec_params(sql).to_a
  data = @select_data
  content_type :json
  @data = data.to_json
end

post '/ip001A_select_js' do
  logger.info "/ip001A_select_js"
  #検索用クラスのインスタンスを呼び出す。
  shinsei_no = params[:shinsei_no_value].to_i
  logger.info shinsei_no
  @select_data =  client.exec_params("select * from shinsei where id=#{shinsei_no}").to_a
  data = @select_data
  content_type :json
  @data = data.to_json
end


post '/ip039A_select_js' do
  logger.info "SinatraPost_ip039A_select_js"
  #検索用クラスのインスタンスを呼び出す。
  yosan_code = params[:yosan_code]
  sql = "select * from yosan where 予算コード='#{yosan_code}'"
  logger.info "ここまできてるよ１"
  @select_data =  client.exec_params(sql).to_a
  logger.info "ここまできてるよ２#{@select_data}"
  data = @select_data
  logger.info "ここまできてるよ３#{data}"
  content_type :json
  @data = data.to_json
  logger.info @data
end

get "/ip001A_select" do
  logger.info "/ip001A_select"
  #引き渡しデータの格納
  @name = session[:user]['name'] # 書き換える
  @authority_param = session[:user]['authority'] #権限情報を渡す。
  @employee_id = session[:employee_id]['employee_id'] # 書き換える
  logger.info @authority_param
  @gamen_param = 1 #検索から遷移
  @shinsei_no =  params[:shinsei_no]
  
  return erb :ip001A
end

post '/ip001A_syonin' do
  @name = session[:user]['name'] # 書き換える
  #画面で入力した値をparamsから取り出す。
  shinsei_no = params[:shinsei_no]
  syoninbi = params[:syoninbi].delete("/")
  syoninsya = params[:syoninsya]
  syonin_comment = params[:syonin_comment]
  logger.info shinsei_no
  logger.info syoninbi
  logger.info syoninsya
  logger.info syonin_comment

  # cliantインスタンスでSQL詰め込み
  client.exec_params("UPDATE shinsei set 申請状況='9' where id=#{shinsei_no}")
  client.exec_params("UPDATE syonin set 承認日=#{syoninbi},承認者id=#{syoninsya},承認コメント='#{syonin_comment}' where 申請番号=#{shinsei_no};")


  @message = "承認が完了しました。"
  return erb :temporary
end

post "/ip082_yosan" do
  #検索用クラスのインスタンスを呼び出す。
  logger.info "/ip082_yosan"
  yosan = params[:yoasn]

  sql = "select 予算コード,処理区分,費用区分, SUM(差引額) from yosan group by 予算コード,処理区分,費用区分;"
    @select_data =  client.exec_params(sql).to_a
    data = @select_data
    content_type :json
    @data = data.to_json
end

get "/ip081A_yosan_meisyo" do
  logger.info "SinatraPost"

  yosan_code = params[:yosan_code]

  sql = ("select * from yosan_masta where 予算コード='#{yosan_code}';")

  @select_data =  client.exec_params(sql).to_a
  data = @select_data
  content_type :json
  @data = data.to_json
end

#サインアウト時に呼ばれる。
delete '/signout' do
  #セッションに空白を入れる
  session[:user] = nil
  return redirect '/login'
end

post "/ip083_yosan" do
  #検索用クラスのインスタンスを呼び出す。
  logger.info "/ip083_yosan"
  yosan = params[:yoasn]

  sql = "select * from yosan;"
    @select_data =  client.exec_params(sql).to_a
    data = @select_data
    content_type :json
    @data = data.to_json
end


# post "/mail" do
#   name = params[:name]
#   email = params[:email]
#   message=params[:message]

#   @isSuccessSendingEmail = 
#     Pony.mail(:to => "awa50141120@gmail.com",
#               :body => message,
#               :subject => "予算承認依頼",
#               :from => "#{name}<#{email}>",
#               :via => :smtp, 
#               :via_options => {
#                 :enable_starttls_auto => true,
#                 :address => "awa50141120@gmail.com",
#                 :port => "587",
#                 :user_name => "awa50141120@gmail.com",
#                 :password => "11451145Awa",
#                 :authentication => :plain,
#                 :domain => "gmail.com"
#               }
#     )
#   erb :index
# end