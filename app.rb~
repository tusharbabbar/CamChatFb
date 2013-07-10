require 'sinatra'
require 'active_record'
require './config/environment'
require './user'
require 'thread'


get '/register_user/:fb_id/:fb_access_token' do 
	User.register_user(params["fb_id"],params["fb_access_token"])
end

get '/get_user_profile/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_profile(params["fb_id"],params["fb_id"],params["fb_access_token"])
end

get '/get_user_photos/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_profile(params["fb_id"],params["fb_id"],params["fb_access_token"])
end

thread = Thread.new do
	while true do
		puts "here"
		value = $fetch_que.pop rescue nil
		fb_id = value[0]
		fb_access_token = value[1]
		User.fetch_user_profile
		User.fetch_user_photos		
	end
end


