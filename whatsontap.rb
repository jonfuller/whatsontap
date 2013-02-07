require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'json'

@@breweries = {sunking: -> {get_sunking_beers},
               bier: -> {get_bier_beers},
               triton: -> {get_triton_beers},
               fountain_square: -> {get_fountain_square_beers},
               flat12: -> {get_flat12_beers}}

get '/' do
  @@breweries.map {|brewery, getter| show_beers(brewery, getter.call)}
end

get '/api' do
  @@breweries.map {|brewery, getter| {name: brewery, beers: getter.call}}.to_json
end

get '/api/:name' do |brewery|
  getter = @@breweries[brewery.downcase.to_sym]

  return 404 unless getter

  getter.call.to_json
end

get '/:brewery' do |brewery|
  getter = @@breweries[brewery.downcase.to_sym]

  return 404 unless getter

  show_beers(brewery, getter.call)
end

def show_beers(brewery_name, beers)
  "<h1>#{brewery_name}</h1>" + beers.map{|beer| "<li>#{beer}</li>"}.join
end

def get_sunking_beers
  require 'mechanize'

  url = "http://www.sunkingbrewing.com/index.php"
  
  agent = Mechanize.new
  age_page = agent.get(url)
  ontap = age_page.search(".ontap").search(".textwidget")

  puts ontap

  beers = ontap.children
    .drop(2)
    .map{|c| c.text}
    .reject{|x| x.empty?}
    .reject{|c| c=="Seasonal Beer"}
end

def get_bier_beers
  # shame(ful|less)ly stolen from https://github.com/netshade/bierbot
  require 'hpricot'
  require 'open-uri'
  
  target = "http://www.bierbrewery.com/index.html"
  
  results = open(target).read rescue nil
  
  if results
    results.gsub!(/<\/?(font|b|img|a|noscript)[^>]*>/im, " ") 
    results.gsub!(/&([a-z]|#[0-9])+;/im, " ")
    results.gsub!(/style\s*=\s*['"].+?['"]/im, "")
    results.gsub!(/<script[^>]*>.*?<\/script>/im, "")
    results.gsub!(/<!--\s*<\/?hs:[^>]*>\s*-->/im, "")
    results.gsub!(/\s{2,}/, " ")
  end
  
  bier_candidates = Hpricot(results).search("*").grep(Hpricot::Text)
  
  ordinals = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "nineth", "tenth", "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth",
  "sixteenth", "seventeenth", "eighteenth", "ninteteenth", "twentieth", "twenty-?first", "twenty-?second", "twenty-?third", "twenty-?fourth", "twenty-?fifth", "twenty-?sixth",
  "twenty-?seventh", "twenty-?eighth", "twenty-?nineth", "thirtieth", "thirty-?first"]
  date_regex = "(Jan(uary)?|Feb(r?uary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sept?(ember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?) ([0-9]+(th|nd|st|rd)?|#{ordinals.join("|")})"
  bier_regex = /((Biers|Beers|Bier) Releases for #{date_regex})|#{date_regex} (biers|beers)/i
  this_week_start = bier_candidates.select { |nd| nd.to_s =~ bier_regex}.first
  bier_candidates = bier_candidates.drop_while{|s| !(s.to_s.strip =~ bier_regex)}
  bier_candidates = bier_candidates.take_while{|s| !(s.to_s.strip =~ /BIER around town.../)}
  bier_candidates = bier_candidates.drop(1)
  bier_candidates.map{|b| b.to_s.strip}.select{|b| b.length > 0}
end

def get_flat12_beers
  require 'hpricot'
  require 'open-uri'
  Hpricot(open("http://flat12.me/blog/classification/ontap/feed/")).search("//item/title/")
end

def get_triton_beers
  require 'hpricot'
  require 'open-uri'
  Hpricot(open("http://tritonbrewing.com/tap-room"))
    .search("#text-3")
    .search("font[@color=#333333]")
    .map{|e| e.to_plain_text}.first.split("\r\n")
    .map{|s| s.strip.gsub("\n", ' ')}
    .select{|s| s.length > 0}
end

def get_fountain_square_beers
  require 'hpricot'
  require 'open-uri'
  Hpricot(open("http://www.fountainsquarebrewery.com/index.php/our-beers"))
    .search("#content")
    .search("//h2")
    .map{|e| e.inner_text}
end
