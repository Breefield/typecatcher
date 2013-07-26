#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'pp'
require 'httparty'
require 'base64'

typekitID = ARGV[0];

# Get the requests from a fake pageload
pp "Requesting Typekit Fonts"
response = `./lib/phantomjs ./lib/load.js #{typekitID}`
requests = response.split("\n").map!{ |r| JSON(r) }

font_path = nil
requests.each do |r|
  # If the path has the correct format, that's where we get the fonts
  if /use\.typekit/ =~ r['url']
    pp "Found Typekit Font Path"
    font_path = r['url']
    break;
  end
end

class Typerequest
  include HTTParty
  headers 'referer' => 'localhost'
end

# A font path was retrieved
if !font_path.nil?

  pp "Requesting: #{font_path}"
  fonts = Typerequest.get(font_path).split('@font-face')
  # Drop EULA
  fonts.shift

  fonts.map! do |font|
    {
      family: font.match(/font\-family:"(.+?)"/i)[1],
      data: font.match(/src:url\(data:.+?base64,(.+?)\)/i)[1],
      weight: font.match(/font\-weight:(.+?);/i)[1],
      style: font.match(/font\-style:(.+?);/i)[1]
    }
  end

  fonts.each do |font|
    filename = "TypeKit-#{font[:family]}-#{font[:style]}-#{font[:weight]}"
    filepath = "fonts/#{filename}"

    # Create WOFF
    file = File.new("#{filepath}.woff", 'w')
    file.write(Base64.decode64(font[:data]))
    file.close

    pp "Saving: #{filepath}"

    # Convert to TTF
    `./lib/woff2sfnt #{filepath}.woff > #{filepath}`
    # Remove WOFF file
    `rm #{filepath}.woff`

    # Move to global font folder, TTF and OTF
    `cp #{filepath} /Library/Fonts/#{filename}.otf`
    `cp #{filepath} /Library/Fonts/#{filename}.ttf`

    # Hide these files
    `chflags hidden /Library/Fonts/#{filename}.otf`
    `chflags hidden /Library/Fonts/#{filename}.ttf`

  end
end