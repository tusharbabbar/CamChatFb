require 'sinatra'
require './user'

post '/chat/register_user' do 
	User.register_user(params["fb_id"],params["fb_access_token"])
end

post '/chat/user_about' do 
	User.post_user_about(params["fb_id"],params["fb_access_token"],params["selections"])
end

get '/chat/get_user_profile/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_profile(params["fb_id"],params["fb_id"],params["fb_access_token"])
end

get '/chat/get_user_about/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_about(params["fb_id"],params["fb_id"],params["fb_access_token"])
end

get '/chat/get_user_photos/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_photos(params["fb_id"],params["fb_id"],params["fb_access_token"])
end

get '/chat/get_user_movies/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_movies(params["fb_id"],params["fb_id"],params["fb_access_token"])
end
get '/chat/get_user_music/:other_fb_id/:fb_id/:fb_access_token' do 
	User.get_user_music(params["fb_id"],params["fb_id"],params["fb_access_token"])	
end
