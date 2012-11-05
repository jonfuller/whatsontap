require 'rubygems'
require 'bundler/setup'
require 'sinatra'

@@breweries = {sunking: -> {get_sunking_beers},
               bier: -> {get_bier_beers}}

get '/' do
  @@breweries.map {|brewery, getter| show_beers(brewery, getter.call)}
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
  main_page = age_page.forms.first.submit(age_page.forms.first.submits[1])
  ontap = main_page.search(".ontap")
  
  beers = ontap.text.split("\n").map{|s| s.strip}.select{|s| s.length > 0}.drop(2).map{|s| s.gsub('Seasonal Beer', '')}
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
  bier_regex = /((Biers|Beers) Releases for #{date_regex})|#{date_regex} (biers|beers)/i
  this_week_start = bier_candidates.select { |nd| nd.to_s =~ bier_regex}.first
  bier_candidates = bier_candidates.drop_while{|s| !(s.to_s.strip =~ /BIER Releases for October 31st:/)}
  bier_candidates = bier_candidates.take_while{|s| !(s.to_s.strip =~ /BIER around town.../)}
  bier_candidates = bier_candidates.drop(1)
  bier_candidates.map{|b| b.to_s.strip}.select{|b| b.length > 0}
end
