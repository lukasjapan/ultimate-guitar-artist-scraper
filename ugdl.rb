require 'bundler/setup'
Bundler.require
require 'uri'
require "capybara"
require "selenium/webdriver"

base_url = "https://www.ultimate-guitar.com/"
tab_base = "https://tabs.ultimate-guitar.com/tab/"

band = ARGV.shift.to_s

Capybara.register_driver :selenium do |app|
    profile = Selenium::WebDriver::Chrome::Profile.new
    profile["download.default_directory"] = "./files"
    Capybara::Selenium::Driver.new(app, browser: :chrome, profile: profile)
end
session = Capybara::Session.new(:selenium)

# Find band
puts "Looking for #{band}"

session.visit base_url + "search.php?search_type=band&value=" + URI.encode(band)

link = session.all('a').select { |e| e.text == band }.first
link = link ? link['href'] : nil

# Find tabs
tab_links = []

while link
    puts "Looking on page #{link}"
    session.visit link

    filter = [ "_guitar_pro_", "_power_" ]
    tab_links += session.all("a").map { |a| a['href'] }.select { |a| a.start_with?(tab_base) && filter.any? { |f| a.match(f) } }

    next_el = session.all("a").select { |a| a['innerHTML'].start_with?('Next') }.first
    link = next_el ? next_el['href'] : nil
end

# Open each and download 

dl = 0

tab_links.each do |link|
    puts "Downloading tab from #{link}"
    session.visit link

    button = session.all("button").select { |b| b["innerHTML"].match("DOWNLOAD") }.first

    puts "No button on #{link}" unless button
    next unless button

    button.click
    sleep 1
    dl += 1
end

# Let downloads finish, sleep 10 seconds just in case
sleep 10

puts "#{dl} files downloaded."