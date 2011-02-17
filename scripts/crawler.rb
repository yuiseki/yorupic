# -*- coding: utf-8 -*-
require 'rubygems'
require 'pit'
require 'mongo'
require 'json'
require 'uri'
require 'open-uri'

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
$setting = Pit.get("lingr.com", :require => {
  "verifier" => "bot verifier, see http://lingr.com/developer",
})
$coll = Mongo::Connection.new.db("latitude").collection("log")

$users.each_key do |username|
	badge = "https://www.google.com/latitude/apps/badge/api?user=#{$users[username]}&type=json"
	data = JSON.parse(open(badge).read())
	lat = data['features'].first['geometry']['coordinates'][0]
	lng = data['features'].first['geometry']['coordinates'][1]
	rgeo = data['features'].first['properties']['reverseGeocode']
	time = data['features'].first['properties']['timeStamp']
  accuracy = data['features'].first['properties']['accurancyInMeters']
  hash = {'user'=>username,
          'lat'=>lat, 'lng'=>lng, 'accurancy'=>accuracy,
          'rgeo'=>rgeo, 'time'=>time}
  # 更新時刻が変わってたら
  results = $coll.find({'user'=>username},{:sort=>['time', 'descending'], :limit=>1}).first.dup()
  unless results['time'] == time
    # DBに記録する
    $coll.insert(hash)
    # 場所も変わってるか確認する
    unless results['rgeo'] == rgeo
        # lingrに通知する
        uri = "http://yorupic.yuiseki.net/#{username}/#{hash['time']}/location.png"
        text = URI.encode("#{username} #{Time.at(hash['time']).strftime('%H:%M')} #{hash['rgeo']}\n#{uri}")
        res = open("http://lingr.com/api/room/say?room=arakawatomonori&bot=arakawatomonori_bot&text=#{text}&bot_verifier=#{$setting['verifier']}")
    end
  end

end









