# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'cgi'
require 'open-uri'
require 'json'
require 'mongo'
require 'lingr.rb'
require 'pit'

$users = {'yuiseki'=>'4598697423011019361',
	'oquno'=>'4601680445375420648',
	'pha'=>'6268540578788313758',
	'takano32'=>'3875590727010536941',
	'mapi'=>'5210418881695603008',
	'hagino3000'=>'-4570121095825315932',
	'niryuu'=>'-4870892304015424950',
	'retlet'=>'-132326932639008225',
	'sora_h'=>'-7457841936955147163',
	'ymrl' => '-3314371951151237192',
	# 'machicolony' => '-2594132176798582609',
}

get '/' do
	resp = []
	$users.sort.each do |username, latitude|
		resp << "@#{username}<br/><img src='/#{username}.png?ts=#{Time.now.to_i.to_s}'><hr>"
	end
	return resp.join('')
end

get '/log' do
	coll = Mongo::Connection.new.db("lingr").collection("arakawatomonori")
	@resp = []
	results = coll.find({},{:sort=>['id', 'descending'], :limit=>30})
	results.each do |row|
		@resp.push "<div style='padding:0px;margin:0px;'><img src='#{row['icon']}' style='width:25px;height:25px;'/>"+
			"<span>#{row['text']}</span><span style='font-size:0.5em;'>#{Time.parse(row['timestamp']).strftime('%H:%M')}</span></div>"
	end
	return @resp.join('')
end

get '/:username.png' do
	badge = "https://www.google.com/latitude/apps/badge/api?user=#{$users[params[:username]]}&type=json"
	data = JSON.parse(open(badge).read())
	lat = data['features'].first['geometry']['coordinates'][0]
	lng = data['features'].first['geometry']['coordinates'][1]
	uri = "http://maps.google.com/maps/api/staticmap?"+
		"center=#{lng},#{lat}" +
		"&zoom=15&size=500x100&sensor=false" +
		"&markers=icon:#{data['features'].first['properties']['photoUrl']}|#{lng},#{lat}"
	puts uri
	cache_control :no_cache
	redirect uri
end

get '/say' do
	config = Pit.get("lingr.com", :require => {
		"username" => "you email in twitter",
		"password" => "your password in twitter"
	})
	begin
	  @lingr = Lingr::Connection.new(config['username'], config['password'], 30, true, nil, nil)
	  puts @lingr
	  @lingr.say('arakawatomonori', 'test')
	end
	return ''
end

get '/lingr' do
	redirect 'http://lingr.com/room/arakawatomonori'
end

post '/callback' do
	result = []
	ling = JSON.parse(params['json'])
	puts ling['events'].first['message'].inspect
	text = ling['events'].first['message']['text']
	hash = {
		'id' => ling['events'].first['message']['id'],
		'icon' => ling['events'].first['message']['icon_url'],
		'timestamp' => ling['events'].first['message']['timestamp'],
		'username' => ling['events'].first['message']['speaker_id'],
		'room' => ling['events'].first['message']['room'],
		'text' => text,
	}
	coll = Mongo::Connection.new.db("lingr").collection("arakawatomonori")
	coll.insert(hash)
	if text =~ /oquno|奥野|おくの|オクノ/ then
		result << "肛門括約筋"
	end
	if text =~ /たかの|タカノ|高野|takano/ then
		result << "ビールくれ"
	end
	if text =~ /マピ|まぴ|mapi|小池|こいけ|コイケ|りっくん/ then
		result << "こいつは本当にクズですね"
		if username == "takano32" then
			result[-1] = "高野くん、今少しうるさかった"
		end
	end
	if text =~ /ダーク|ugdark/ then
		result << "いっしょに風俗行こうよ！！！"
	end
	if text =~ /ノノリリ|nonoriri|ののりり/ then
		result << "やつがほんとうの荒川智則なのかッ？？？"
	end
	if text =~ /うんこ|ウンコ|[Uu][Nn][Kk][Oo]/ then
		result << "ショッキング！"
	end
	if text =~ /^[:space:]*[Dd]+([:space:]*|$)/ then
		result << "だるい"
	end

	if text =~ (/^L(\w+)\s?/) then
		name = $1
		puts name.inspect
		if $users.has_key?(name)
			result << "http://yorupic.yuiseki.net/#{name}.png?ts=#{Time.now.to_i.to_s}"
		else
			result << "https://www.google.com/latitude/apps"
			result << "Google公開ロケーションバッジを有効にして、"
			result << "一番下の「デベロッパー情報」ってところにある公開JSONフィードのIDおしえて～"
		end
	end
	result.join("\n")
end


