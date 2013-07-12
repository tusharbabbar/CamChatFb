require 'sinatra'
require './user'

get '/register_user/:fb_id/:fb_access_token' do 
	User.register_user(params["fb_id"],params["fb_access_token"])
end

get '/get_user_profile/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_profile(params["fb_id"],params["fb_id"],params["fb_access_token"])
end

get '/get_user_photos/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_photos(params["fb_id"],params["fb_id"],params["fb_access_token"])
get '/get_user_movies/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_movies(params["fb_id"],params["fb_id"],params["fb_access_token"])	
end
