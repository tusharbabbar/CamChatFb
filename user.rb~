require 'mongo'
require 'fb_graph'
require 'json'
require './fetcher'
require 'sidekiq'

include Mongo

$Mongodb = MongoClient.new("localhost",27017).db("chatdb")
$People = $Mongodb.collection("people")
$PeopleProfiles = $Mongodb.collection("people_profiles")
$PeopleMovies = $Mongodb.collection("people_movies")
$PeoplePhotos = $Mongodb.collection("people_photos")

class NoUserError < StandardError
	def message
		"No user With the given Fb_Id exists"
	end
end

class UserAlreadyExistsError < StandardError
	def message
		"The user already exists in the system"
	end
end

class TokenMisMatchError < StandardError
	def message
		"The Fb_if and Access_token donot match"
	end
end

module User

	#@@fetch_que = Queue.new
	#attr_accessor :fetch_que
	
	
	def self.validate_token fb_id, fb_access_token
		id = FbGraph::User.me("#{fb_access_token}").fetch.raw_attributes["id"]
		if !(fb_id == id) then raise TokenMisMatchError end
	end
	
	def self.authenticate_user fb_id, fb_access_token
		user = $People.find("fb_id"=>fb_id)
		user = user.to_a.first
		if !(user) 
			raise NoUserError
		elsif !(user["fb_access_token"]==fb_access_token)
			validate_token fb_id, fb_access_token
			user["fb_access_token"] = fb_access_token
			$People.update({"_id"=>user["_id"]},user)
		end
	end
	
	def self.register_user fb_id, fb_access_token
		begin
			puts ("\n\n\n\n#{Sidekiq::Stats.new.processed}\n\n\n\n ")
			if $People.find("fb_id"=>fb_id).to_a.first
				raise UserAlreadyExistsError
			end
			validate_token fb_id, fb_access_token
			doc = {"fb_id"=>fb_id,"fb_access_token"=>fb_access_token}
			$People.insert doc
			HardWorker.perform_async fb_id,fb_access_token
			#$exchng.publish("#{fb_id}\|#{fb_access_token}", :routing_key => $fetch_que.name)
#			puts $fetch_que.length	
			return {"error"=>false,"success"=>true,"message"=>"user successfully added to system"}.to_json
		
		rescue UserAlreadyExistsError => e
			return {"error"=>true,"success"=>false,"message"=>e.message}.to_json

		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"message"=>e.message}.to_json
		end
	end
	
	def self.get_user_profile other_fb_id, fb_id, fb_access_token
		begin
			User.authenticate_user fb_id,fb_access_token
			x = $PeopleProfiles.find("fb_id"=>other_fb_id).to_a.first
			x.delete("_id")
			return x.to_json
		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"message"=>e.message}.to_json
		else	
			return {"error"=>true,"success"=>false,"message"=>"Internal Server Error"}.to_json
		end
	end
	
	def self.get_user_photos other_fb_id, fb_id, fb_access_token
		begin
			User.authenticate_user fb_id,fb_access_token
			x = $PeoplePhotos.find("fb_id"=>other_fb_id).to_a.first
			x.delete("_id")
			return x.to_json
		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"message"=>e.message}.to_json
		else	
			return {"error"=>true,"success"=>false,"message"=>"Internal Server Error"}.to_json
		end
	end
	
	def self.get_user_movies other_fb_id, fb_id, fb_access_token
		begin
			User.authenticate_user fb_id,fb_access_token
			x = $PeopleMovies.find("fb_id"=>other_fb_id).to_a.first
			x.delete("_id")
			return x.to_json
		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"message"=>e.message}.to_json
		else	
			return {"error"=>true,"success"=>false,"message"=>"Internal Server Error"}.to_json
		end
	end
	
end

# Task Queue Operations Defined Here

class HardWorker 
	include Sidekiq::Worker
	
	def perform fb_id, fb_access_token
		puts fb_id
		Fetcher.fetch_user_profile fb_id, fb_access_token
		Fetcher.fetch_user_photos fb_id, fb_access_token
		Fetcher.fetch_user_movies fb_id, fb_access_token
	end
end

#$fetch_que.subscribe do |delivery_info, metadat, payload|
#	payload = payload.split("|")
#	fb_id = payload[0]
#	fb_access_token = payload[1]
#	puts payload
#	Fetcher.fetch_user_profile fb_id, fb_access_token
#	Fetcher.fetch_user_photos fb_id, fb_access_token
#end
