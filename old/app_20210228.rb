require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'pg'
require './src/web/ip002/SearchConditions' #他クラスをrequire（import）する際は./が必要

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


def Conditions(shinseibi:, konyubi:, shinseisya:, hinmei:, maker:)
        #テーブルへアクセスするSQLを定義する。
        sql_buys = "SELECT * FROM buys"
        sort = "order by id"

        #検索条件が空の場合、全レコードを対象に検索する。
        if shinseibi.empty?
            if konyubi.empty?
                if shinseisya.empty?
                    if hinmei.empty?
                        if maker.empty?
                          return "#{sql_buys} #{sort}"
                        end
                    end
                end
            end
        end

        #検索条件に1つ以上データがある場合、条件付きの検索を行う。
        where = "where "
        #申請日の検索条件を設定する。
        if shinseibi.empty?
            shinseibi_where = nil
        else
            shinseibi_where = "申請日='#{shinseibi}'"
        end

        #購入日の検索条件を設定する。
        if konyubi.empty?
            konyubi_where = nil
        else
            konyubi_where = "AND 購入日='#{konyubi}'"
        end

        #申請者の検索条件を設定する。
        if shinseisya.empty?
            shinseisya_where = nil
        else
            shinseisya_where = "AND 申請者='#{shinseisya}'"
        end

        #品名の検索条件を設定する。
        if hinmei.empty?
            hinmei = nil
        else
            hinmei = "AND 品名='#{hinmei}'"
        end

        #メーカーの検索条件を設定する。
        if maker.empty?
            maker = nil
        else
            maker = "AND 品名='#{maker}'"
        end

        sql = "#{sql_buys} #{where} #{shinseibi_where} #{konyubi_where} #{sort}"
        return sql
end

def Conditions2(shinseibi:, konyubi:, shinseisya:, hinmei:, maker:)
  #テーブルへアクセスするSQLを定義する。
  sql_buys = "SELECT * FROM buys"
  sort = "order by id"

  #検索条件が空の場合、全レコードを対象に検索する。
  if shinseibi.empty?
      if konyubi.empty?
          if shinseisya.empty?
              if hinmei.empty?
                  if maker.empty?
                    return "#{sql_buys} #{sort}"
                  end
              end
          end
      end
  end

  select_1 = [
    {col:"申請日", data:shinseibi},
    {col:"購入日", data:konyubi},
    {col:"申請者", data:shinseisya},
    {col:"品名", data:hinmei},
    {col:"メーカー", date:maker}]
  sql_array = ["select * from buys where"]

  select_1.each do |x|
    if x[:data].empty?
      x = nil
    else
      sql_array.push("#{x[:col]} = '#{x[:data]}'")
    end
  end

  sql = sql_array.join

  return sql
end