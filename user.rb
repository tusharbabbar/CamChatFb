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
$PeopleMusic = $Mongodb.collection("people_music")
$PeopleAbout = $Mongodb.collection("people_about")

class NoUserError < StandardError
	def message
		"No user With the given Fb_Id exists"
	end
end

class ServerError < StandardError
	def message
		"Some Problem has occurred!!! please contact the backend develpoer"
	end
end

class NoContentError < StandardError
	def message
		"No content found for the User Given"
	end
end


class UserAlreadyExistsError < StandardError
	def message
		"The user already exists in the system"
	end
end

class TokenMisMatchError < StandardError
	def message
		"The Fb_id and Fb_Access_Token donot match"
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
			if $People.find("fb_id"=>fb_id).to_a.first
				raise UserAlreadyExistsError
			end
			validate_token fb_id, fb_access_token
			doc = {"fb_id"=>fb_id,"fb_access_token"=>fb_access_token,}
			$People.insert doc
			HardWorker.perform_async fb_id,fb_access_token	
			return {"error"=>false,"success"=>true,"status_code"=>201,"message"=>"user successfully added to system"}.to_json
		
		rescue UserAlreadyExistsError => e
			return {"error"=>true,"success"=>false,"status_code"=>461,"message"=>e.message}.to_json

		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"status_code"=>462,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"status_code"=>463,"message"=>e.message}.to_json
		end
	end
	
	def self.post_user_about fb_id, fb_access_token, selections
		begin
			if $PeopleAbout.find("fb_id"=>fb_id).to_a.first
                                raise UserAlreadyExistsError
                        end
			validate_token fb_id, fb_access_token
			doc = {"fb_id"=>fb_id,"selections"=>selections,"message"=>true}
			$PeopleAbout.insert doc	
			return {"error"=>false,"success"=>true,"status_code"=>201,"message"=>"user about successfully added to system"}.to_json
		rescue UserAlreadyExistsError => e
                        return {"error"=>true,"success"=>false,"status_code"=>461,"message"=>"User About has already been updated in database"}.to_json

		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"status_code"=>462,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"status_code"=>463,"message"=>e.message}.to_json
		end
	end
	
	def self.get_user_profile other_fb_id, fb_id, fb_access_token
		begin
			User.authenticate_user fb_id,fb_access_token
			x = $PeopleProfiles.find("fb_id"=>other_fb_id).to_a.first
			if !(x) then raise NoContentError end
			x.delete("_id")
			doc = {"error"=>false,"success"=>true,"status_code"=>200,"fb_id"=>x["fb_id"],"data"=>x}
			return doc.to_json
		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"status_code"=>462,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"status_code"=>463,"message"=>e.message}.to_json
		
		rescue NoContentError => e
			return {"error"=>true,"success"=>false,"status_code"=>520,"message"=>e.message}.to_json
		end
	end
	
	def self.get_user_photos other_fb_id, fb_id, fb_access_token
		begin
			User.authenticate_user fb_id,fb_access_token
			x = $PeoplePhotos.find("fb_id"=>other_fb_id).to_a.first
			if !(x) then raise NoContentError end
			doc = {"error"=>false,"success"=>true,"status_code"=>200,"fb_id"=>x["fb_id"],"data"=>x["photos"],"message"=>x["message"]}
			return doc.to_json
		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"status_code"=>462,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"status_code"=>463,"message"=>e.message}.to_json
		
		rescue  NoContentError => e
			return {"error"=>true,"success"=>false,"status_code"=>520,"message"=>e.message}.to_json
		end
	end
	
	def self.get_user_about other_fb_id, fb_id, fb_access_token
		begin
			User.authenticate_user fb_id,fb_access_token
			x = $PeopleAbout.find("fb_id"=>other_fb_id).to_a.first
			if !(x) then raise NoContentError end
			doc = {"error"=>false,"success"=>true,"status_code"=>200,"fb_id"=>x["fb_id"],"data"=>x["selections"],"message"=>x["message"]}
			return doc.to_json
			return x.to_json
		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"status_code"=>462,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"status_code"=>463,"message"=>e.message}.to_json
		
		rescue NoContentError => e
			return {"error"=>true,"success"=>false,"status_code"=>520,"message"=>e.message}.to_json
		end
	end
	
	def self.get_user_movies other_fb_id, fb_id, fb_access_token
		begin
			User.authenticate_user fb_id,fb_access_token
			x = $PeopleMovies.find("fb_id"=>other_fb_id).to_a.first
			if !(x) then raise NoContentError end
			doc = {"error"=>false,"success"=>true,"status_code"=>200,"fb_id"=>x["fb_id"],"data"=>x["movies"],"message"=>x["message"]}
			return doc.to_json
		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"status_code"=>462,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"status_code"=>463,"message"=>e.message}.to_json
		
		rescue NoContentError => e
			return {"error"=>true,"success"=>false,"status_code"=>520,"message"=>e.message}.to_json
		end
	end
	
	def self.get_user_music other_fb_id, fb_id, fb_access_token
		begin
			User.authenticate_user fb_id,fb_access_token
			x = $PeopleMusic.find("fb_id"=>other_fb_id).to_a.first
			if !(x) then raise NoContentError end
			doc = {"error"=>false,"success"=>true,"status_code"=>200,"fb_id"=>x["fb_id"],"data"=>x["music"],"message"=>x["message"]}
			return doc.to_json
		rescue FbGraph::InvalidToken => e
			return {"error"=>true,"success"=>false,"status_code"=>462,"message"=>e.to_s}.to_json
		
		rescue TokenMisMatchError => e
			return {"error"=>true,"success"=>false,"status_code"=>463,"message"=>e.message}.to_json
		
		rescue NoContentError => e
			return {"error"=>true,"success"=>false,"status_code"=>520,"message"=>e.message}.to_json
		end
	end
	
end

# Task Queue Operations Defined Here

class HardWorker 
	include Sidekiq::Worker
	
	def perform fb_id, fb_access_token
		puts fb_id
		#Fetcher.fetch_user_profile fb_id, fb_access_token
		Fetcher.fetch_user_photos fb_id, fb_access_token
		Fetcher.fetch_user_movies fb_id, fb_access_token
		Fetcher.fetch_user_music fb_id, fb_access_token
	end
end

