require './user'

module Fetcher

	def self.fetch_user_photos fb_id, fb_access_token
		photos = FbGraph::User.me(fb_access_token).photos ({"limit"=>150})
		puts "here1"
		user_photos = []
		photos.each do |photo|
			photo = photo.source
			small_photo = photo.gsub("s720x720","").gsub("_n","_s")
			large_photo = photo
			user_photos << {"small_src"=>small_photo,"large_src"=>large_photo}
		end
		doc = {"fb_id"=>fb_id,"photos"=>user_photos}
		$PeoplePhotos.insert doc
	end
				
#	def self.fetch_user_profile fb_id, fb_access_token
#		user = FbGraph::User.me(fb_access_token).fetch
#		if user.name then username = user.name end
#		if user.location
#		location = user.location.raw_attributes["name"].split(", ")
#		city = location[0]
#		country = location[1]
#		end
#		interested_in = user.interested_in
#		education = user.education
#		schools = []
#		education.each do |edu|
#			name = edu.school.name
#			type = edu.type
#			schools << [name , type]
#		end
#		relationship_status = user.relationship_status
#		about = user.bio
#		work = user.work
#		jobs = []
#		work.each do |w|
#			jobs << [w.employer.name, w.position.name]
#		end
#		doc = {"fb_id"=>fb_id,"name"=>username,"city"=>city,"country"=>country,"interested_in"=>interested_in,"relationship_status"=>relationship_status,"education"=>schools,"work"=>jobs}	
#		$PeopleProfiles.insert doc
#	end
	
	def self.fetch_user_movies fb_id,fb_access_token
		movies = FbGraph::User.me(fb_access_token).movies ({"limit"=>150})
		movie_array = []
		movies.each do |movie|
			name = movie.name
			url_name = name.gsub(" ","%20")
			res = ""
			tmdb_res = JSON.parse(open("http://api.themoviedb.org/3/search/movie?api_key=a909408b0692355bdcd1be7a28e55bab&query=#{url_name}").read)["results"]
			if tmdb_res then tmdb_res.map {|r| r["title"]==name ? res=r : r} else next end
			movie_array << {"small_src"=>"http://d3gtl9l2a4fn1j.cloudfront.net/t/p/w92#{res["poster_path"]}" }
		end
		doc = {"fb_id"=>fb_id , "movies" => movie_array}
		$PeopleMovies.insert doc
	end
	
	def self.fetch_user_music fb_id, fb_access_token
		musics = FbGraph::User.me(fb_access_token).music ({"limit"=>150})
		music_array = []
		musics.each do |music|
			name = music.name
			url_name = name.gsub(" ","%20")
			res = JSON.parse(open("http://ws.audioscrobbler.com/2.0/?method=artist.search&artist=#{url_name}&api_key=db660f2f6834e676949273a6d9064c4c&format=json").read)["results"]["artistmatches"]["artist"].first
			if res then image_url = res["image"][2]["#text"] else next end
			music_array << {"small_src"=>image_url}	
		end
		#puts "hello"
		doc = {"fb_id"=>fb_id, "music" => music_array}
		#puts doc
		$PeopleMusic.insert doc	
	end
		
end

