require "net/http"
require "uri"
require 'json'
require 'to_name'
require 'table_print'
require 'progress_bar'

stash_path = "/Users/usman/Desktop/Personal/Downloaded/*"

def get_files_at path
	files = Dir.glob(path)
	files.map{|file| ToName.to_name(file).name.downcase}.uniq!
end

def camelize str
	return str.split(' ').map {|w| w.capitalize}.join(" ")
end

def movie_detail file
	name = URI.escape("http://www.omdbapi.com/?t=#{file}")
  	uri = URI.parse(name)
  	response = Net::HTTP.get_response(uri)
  	json = JSON.parse(response.body)
  	json unless json["Response"] == "False"
end

def movie_from file, json
	rating = json["imdbRating"]
  	plot = json["Plot"]
  	year = json["Year"]
  	{:name => camelize(file), :rating => rating, :year => year, :plot => plot}
end

def updated_ratings files
	movies = Array.new
	count = 0
	numFiles = files.length
	files.each do |file|
		next if file.empty?
		yield
	  	json = movie_detail file
	  	movies << movie_from(file, json) unless json.nil?
	end

	movies.sort {|a,b| b[:rating] <=> a[:rating] }
end

puts "\n"

files = get_files_at(stash_path)
bar = ProgressBar.new(files.length, :bar, :counter, :eta)
movies = updated_ratings(files) { bar.increment! }

puts "\n\n"
tp movies, :name, :rating, :year, :plot => {:width => 100}

