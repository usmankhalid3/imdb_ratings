require "net/http"
require "uri"
require 'json'
require 'to_name'
require 'table_print'
require 'progress_bar'
require 'YAML'

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
  	{
  		:name => camelize(file), 
  		:rating => json["imdbRating"], 
  		:year => json["Year"], 
  		:plot => json["Plot"]
  	}
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

def clear_screen
	system "clear" or system "cls"
end

def save movies, path
	f = File.open("#{path}/ratings", 'w')
	f.write(YAML.dump(movies))
	rescue SystemCallError
		puts "Data could not be saved!"
  		return nil
end

def open_from path
	f = File.read("#{path}/ratings")
	YAML.load(f)
	rescue SystemCallError
  		return nil
end

def show ratings
	clear_screen
	tp ratings, :name, :rating, :year, :plot => {:width => 100} unless ratings.nil?
end

def main path
	old_ratings = open_from path
	show old_ratings
	files = get_files_at("#{path}/*")
	bar = ProgressBar.new(files.length, :bar, :counter, :eta)
	new_ratings = updated_ratings(files) { bar.increment! }
	show new_ratings
	save new_ratings, path
end

src = "/Users/usman/Desktop/Personal/Downloaded"
main src

