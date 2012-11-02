require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'mechanize'

get '/' do
  "<h1>Sunking</h1>" + get_sunking_beers.map{|beer| "<li>#{beer}</li>"}.join
end


def get_sunking_beers
  url = "http://www.sunkingbrewing.com/index.php"
  
  agent = Mechanize.new
  age_page = agent.get(url)
  main_page = age_page.forms.first.submit(age_page.forms.first.submits[1])
  ontap = main_page.search(".ontap")
  
  beers = ontap.text.split("\n").map{|s| s.strip}.select{|s| s.length > 0}.drop(2).map{|s| s.gsub('Seasonal Beer', '')}
end
