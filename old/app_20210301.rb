require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'pg'
require './src/web/ip002/SearchConditions' #他クラスをrequire（import）する際は./が必要
require 'logger'

logger = Logger.new('sinatra.log')
SearchConditions = SearchConditions.new

client = PG::connect(
  :host => "localhost",
  :user => ENV.fetch("USER", "awa1120"), :password => 'awa1120',
  :dbname => "myapp")

enable :sessions

get "/index" do
    @name = session[:user]['name'] # 書き換える
    return erb :index
end

get '/login' do
   # :layout => nilの指定で、レイアウトファイルを使用しないことが可能。
   return erb :login, :layout => nil
end

#postされる。
post '/signin' do
  email = params[:email]
  password = params[:password]
  user = client.exec_params("SELECT * FROM users WHERE email = '#{email}' AND password = '#{password}'").to_a.first
  if user.nil?
    return erb :login
  else
    session[:user] = user
    return redirect '/index'
  end
end

#業務コントローラエリア
get '/ip001A' do
  # :layout => nilの指定で、レイアウトファイルを使用しないことが可能。
  return erb :ip001A
end

post '/ip001A_insert' do
  #画面で入力した値をparamsから取り出す。
  @dete = [
    @shinseibi= params[:shinseibi],
    @konyubi= params[:konyubi],
    @shinseisya= params[:shinseisya],
    @hinmei= params[:hinmei],
    @maker= params[:maker],
    @yosan_code= params[:yosan_code],
    @zeikomi= params[:zeikomi],
    @zeinuki= params[:zeinuki],
    @zeigaku= params[:zeigaku]]
  
  # cliantインスタンスで詰め込み
  client.exec_params("INSERT INTO buys (申請日,購入日,申請者,品名,メーカー,予算コード,税込額,税抜額,税額) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)",
  [@shinseibi,@konyubi,@shinseisya,@hinmei,@maker,@yosan_code,@zeikomi,@zeinuki,@zeigaku]);
  return erb :temporary
end

get '/tables' do
  # :layout => nilの指定で、レイアウトファイルを使用しないことが可能。
  # @select_data = client.exec_params("select * from buys")
  return erb :tables
end

get '/ip002A' do
  #@select_data = []
  #@select_data = client.exec_params("select * from buys").to_a
  @select_data =[]
  return erb :ip002A
end

post '/ip002A_select' do
  # @ip002A_selectData = {
  # shinseibi: params[:shinseibi],
  # konyubi: params[:konyubi],
  # shinseisya: params[:shinsxeisya],
  # hinmei: params[:hinmei],
  # maker: params[:maker],
  # hinban: params[:hinban]} 

  #検索用クラスのインスタンス変数を呼び出す。
  #SearchConditions = SearchConditions.new
  #sql = SearchConditions.Conditions(
  sql = Conditions(
  shinseibi: params[:shinseibi],
  konyubi: params[:konyubi],
  shinseisya: params[:shinseisya],
  hinmei: params[:hinmei],
  maker: params[:maker])

  @select_data =  client.exec_params(sql)
  # client.exec_params("select * from buys WHERE 申請日=$1 or 購入日=$2 or 申請者=$3 or 品名=$4 or メーカー=$5 or 品番=$6",[shinseibi,konyubi,shinseisya,hinmei,maker,hinban]).to_a
  # @select_data = client.exec_params("select * from buys where 申請日='#{shinseibi}' and 購入日='#{konyubi}' and 申請者='#{shinseisya}' and 品名='#{hinmei}' and メーカー='#{maker}' and 品番='#{hinban}';").to_a
  return erb :ip002A
  # return erb :ip002A
end

post '/ip002A_select_js' do
  logger.info "SinatraPost"
  # sql = Conditions(
  sql = SearchConditions.Conditions(
  shinseibi_s: params[:shinseibi1_s],
  shinseibi_e: params[:shinseibi1_e],
  konyubi_s: params[:konyubi2_s],
  konyubi_e: params[:konyubi2_e],
  shinseisya: params[:shinseisya3],
  hinmei: params[:hinmei4],
  maker: params[:maker5])

  @select_data =  client.exec_params(sql).to_a
  # client.exec_params("select * from buys WHERE 申請日=$1 or 購入日=$2 or 申請者=$3 or 品名=$4 or メーカー=$5 or 品番=$6",[shinseibi,konyubi,shinseisya,hinmei,maker,hinban]).to_a
  # @select_data = client.exec_params("select * from buys where 申請日='#{shinseibi}' and 購入日='#{konyubi}' and 申請者='#{shinseisya}' and 品名='#{hinmei}' and メーカー='#{maker}' and 品番='#{hinban}';").to_a
  data = @select_data
  content_type :json
  @data = data.to_json
  # return erb :ip002A
end


def Conditions(shinseibi_s:, shinseibi_e:, konyubi_s:, konyubi_e:, shinseisya:, hinmei:, maker:)
      logger.info "Conditions"
        #テーブルへアクセスするSQLを定義する。
        sql_buys = "SELECT * FROM buys "
        sort = "order by id "
        #すでにWhere句が宣言されているか確認するフラグ
        first_flag = 0

        #検索条件が空の場合、全レコードを対象に検索する。
        if shinseibi_s.empty?
          if shinseibi_e.empty?
            if konyubi_s.empty?
              if konyubi_e.empty?
                if shinseisya.empty?
                  if hinmei.empty?
                    if maker.empty?
                      return "#{sql_buys} #{sort}"
                    end
                  end
                end
              end
            end
          end
        end
        
        #申請日の検索条件を設定する。
        if shinseibi_s.empty?
          if shinseibi_e.empty?
            shinseibi_where = nil
          else
            if first_flag==0
              #終了が入力されている場合
              shinseibi_where = "WHERE 申請日 BETWEEN '00000000' AND '#{shinseibi_e}' "
              first_flag=1
            else
              shinseibi_where = "AND 申請日 BETWEEN '00000000' AND '#{shinseibi_e}' "
            end
          end
        else
          if shinseibi_e.empty?
            if first_flag==0
              #開始が入力されている場合
              shinseibi_where = "WHERE 申請日 BETWEEN '#{shinseibi_s}' AND '99999999' "
              first_flag=1
            else
              shinseibi_where = "AND 申請日 BETWEEN '#{shinseibi_s}' AND '99999999' "
            end
          else
            if first_flag==0
              #開始、終了が入力されている場合
              shinseibi_where = "WHERE 申請日 BETWEEN '#{shinseibi_s}' AND '#{shinseibi_e}' "
              first_flag=1
            else
              shinseibi_where = "AND 申請日 BETWEEN '#{shinseibi_s}' AND '#{shinseibi_e}' "
            end
          end
        end

        #購入日の検索条件を設定する。
        if konyubi_s.empty?
          if konyubi_e.empty?
            konyubi_where = nil
          else
            if first_flag==0
              #終了が入力されている場合
              konyubi_where = "WHERE 購入日 BETWEEN '00000000' AND '#{konyubi_e}' "
              first_flag=1
            else
              konyubi_where = "AND 購入日 BETWEEN '00000000' AND '#{konyubi_e}' "
            end
          end
        else
          if konyubi_e.empty?
            konyubi_e_where = nil
           if first_flag==0
             #開始が入力されている場合
             konyubi_where = "WHERE 購入日 BETWEEN '#{konyubi_s}' AND '99999999' "
             first_flag=1
           else
             konyubi_where = "AND 購入日 BETWEEN '#{konyubi_s}' AND '99999999' "
           end
          else
            if first_flag==0
              #開始、終了が入力されている場合
              konyubi_where = "WHERE 購入日 BETWEEN '#{konyubi_s}' AND '#{konyubi_e}' "
              first_flag=1
            else
              konyubi_where = "AND 購入日 BETWEEN '#{konyubi_s}' AND '#{konyubi_e}' "
            end
          end
        end
      

        #申請者の検索条件を設定する。
        if shinseisya.empty?
          shinseisya_where = nil
        else
          if first_flag==0
            shinseisya_where = "WHERE 申請者 LIKE '%#{shinseisya}%' "
            first_flag=1
          else
            shinseisya_where = "AND 申請者 LIKE '%#{shinseisya}%' "
          end
        end

        #品名の検索条件を設定する。
        if hinmei.empty?
          hinmei_where = nil
        else
          if first_flag==0
            hinmei_where = "WHERE 品名 LIKE '%#{hinmei}%' "
            first_flag=1
          else
            hinmei_where = "AND 品名 LIKE '%#{hinmei}%' "
          end
        end

        #メーカーの検索条件を設定する。
        if maker.empty?
          maker_where = nil
        else
          if first_flag==0
            maker_where = "WHERE メーカー LIKE '%#{maker}%' "
            first_flag=1
          else
            maker_where = "AND メーカー LIKE '%#{maker}%' "
          end
        end

        sql = "#{sql_buys} #{shinseibi_where} #{konyubi_where} #{shinseisya_where} #{hinmei_where} #{maker_where} #{sort}"
        return sql
end