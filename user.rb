require 'mongo'
require 'fb_graph'
require 'json'
require 'thread'
include Mongo

$fetch_que = Queue.new

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
	
	Mongodb = MongoClient.new("localhost",27017).db("chatdb")
	People = Mongodb.collection("people")
	PeopleProfiles = Mongodb.collection("people_profile")
	PeopleMovies = Mongodb.collection("people_movies")
	PeoplePhotos = Mongodb.collection("people_photos")
	
	def self.validate_token fb_id, fb_access_token
		id = FbGraph::User.me("#{fb_access_token}").fetch.raw_attributes["id"]
		if !(fb_id == id) then raise TokenMisMatchError end
	end
	
	def self.authenticate_user fb_id, fb_access_token
		user = People.find("fb_id"=>fb_id)
		user = user.to_a.first
		if !(user) 
			raise NoUserError
		elsif !(user["fb_access_token"]==fb_access_token)
			validate_token fb_id, fb_access_token
			user["fb_access_token"] = fb_access_token
			people.update({"_id"=>user["_id"]},user)
		end
	end
	
	def self.register_user fb_id, fb_access_token
		begin
			if People.find("fb_id"=>fb_id).to_a.first
				raise UserAlreadyExistsError
			end
			validate_token fb_id, fb_access_token
			doc = {"fb_id"=>fb_id,"fb_access_token"=>fb_access_token}
			People.insert doc
			$fetch_que << [fb_id,fb_access_token]
			puts $fetch_que.length	
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
			x = PeopleProfiles.find("fb_id"=>other_fb_id).to_a.first
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
			x = PeoplePhotos.find("fb_id"=>other_fb_id).to_a.first
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
	
	def self.fetch_user_photos fb_id, fb_access_token
		photos = FbGraph::User.me(fb_access_token).photos ({"limit"=>150})
		user_photos = []
		photos.each do |photo|
			photo = photo.source
			small_photo = photo.gsub("s720x720","").gsub("_n","_s")
			large_photo = photo
			user_photos << [small_photo,large_photo]
		end
		doc = {"fb_id"=>fb_id,"photos"=>user_photos}
		PeoplePhotos.insert doc
	end			
	def self.fetch_user_profile fb_id, fb_access_token
		user = FbGraph::User.me(fb_access_token).fetch
		name = user.name
		location = user.location.raw_attributes["name"].split(", ")
		city = location[0]
		country = location[1]
		interested_in = user.interested_in
		education = user.education
		schools = []
		education.each do |edu|
			name = edu.school.name
			type = edu.type
			schools = [name , type]
		end
		relationship_status = user.relationship_status
		about = user.bio
		work = user.work
		jobs = []
		work.each do |w|
			jobs << [w.employer.name, w.position.name]
		end
		doc = {"fb_id"=>fb_id,"name"=>name,"city"=>city,"country"=>country,"interested_in"=>intersted_in,"relationship_status"=>relationship_status,"education"=>schools,"work"=>jobs}	
		PeopleProfiles.insert doc
	end
end


		
