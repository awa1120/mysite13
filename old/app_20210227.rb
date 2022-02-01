require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'pg'
require "src/web/ip002/SearchConditions"

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

# post '/ip001A_insert' do
#   # :layout => nilの指定で、レイアウトファイルを使用しないことが可能。
#   @dete =[
#   @shinseibi= params[:shinseibi],
#   @konyubi= params[:konyubi],
#   @shinseisya= params[:shinseisya],
#   @hinmei= params[:hinmei],
#   @hinban= params[:hinban],
#   @maker= params[:maker],
#   @zeikomi= params[:zeikomi],
#   @zeinuki= params[:zeinuki],
#   @zeigaku= params[:zeigaku]]
#   return erb :temporary
# end

post '/ip001A_insert' do
  #画面で入力した値をparamsから取り出す。
  @dete = [
    @shinseibi= params[:shinseibi],
    @konyubi= params[:konyubi],
    @shinseisya= params[:shinseisya],
    @hinmei= params[:hinmei],
    @hinban= params[:hinban],
    @maker= params[:maker],
    @zeikomi= params[:zeikomi],
    @zeinuki= params[:zeinuki],
    @zeigaku= params[:zeigaku]]
  
  
  # cliantインスタンスで詰め込み
  client.exec_params("INSERT INTO buys (申請日,購入日,申請者,品名,メーカー,予算コード,税込額,税抜額,税額) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)",
  [@shinseibi,@konyubi,@shinseisya,@hinmei,@maker,@hinban,@zeikomi,@zeinuki,@zeigaku]);
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
  @ip002A_selectData = {
  shinseibi: params[:shinseibi],
  konyubi: params[:konyubi],
  shinseisya: params[:shinsxeisya],
  hinmei: params[:hinmei],
  maker: params[:maker],
  hinban: params[:hinban]} 

  SearchConditions = SearchConditions.new
  SearchConditions.Conditions(@ip002A_selectData)

  @select_data = 
  client.exec_params("select * from buys").to_a
  # client.exec_params("select * from buys WHERE 申請日=$1 or 購入日=$2 or 申請者=$3 or 品名=$4 or メーカー=$5 or 品番=$6",[shinseibi,konyubi,shinseisya,hinmei,maker,hinban]).to_a
  # @select_data = client.exec_params("select * from buys where 申請日='#{shinseibi}' and 購入日='#{konyubi}' and 申請者='#{shinseisya}' and 品名='#{hinmei}' and メーカー='#{maker}' and 品番='#{hinban}';").to_a

  return erb :ip002A
end

#2回以上使うかどうか？で判断した方が良い。
