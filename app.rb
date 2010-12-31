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
	'ymrl' => '-3314371951151237192',
}

get '/' do
	resp = []
	$users.each_key do |username|
		resp << "<img src='/#{username}.png?ts=#{Time.now.to_i.to_s}'>"
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

get '/lingr' do
	#@lingr = Lingr::Connection.new(@user, @password, @backlog_count, true, @logger, @api_key)
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
	if text =~ /奥野|oquno|おくの/ then
		result << "肛門括約筋"
	end
	if text.include?("@")
		name = text.scan(/^@(\w+)\s?/).first.first
		puts name.inspect
		if $users.has_key?(name)
			result << "http://yuiseki.net:4589/#{name}.png?ts=#{Time.now.to_i.to_s}"
		else
			result << "https://www.google.com/latitude/apps \nGoogle公開ロケーションバッジを有効にして、"+
				"一番下の「デベロッパー情報」ってところにある公開JSONフィードのIDおしえて～"
		end
	end
	result.join("\n")
end


