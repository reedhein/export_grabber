require 'nokogiri'
require 'mechanize'
require 'pry'
require 'pry-byebug'
require 'open-uri'
require 'selenium-webdriver'
require 'watir'

cnf = YAML::load(File.open('secrets.yml'))
# login_page    = 'https://login.salesforce.com/'
download_page = 'https://na34.salesforce.com/ui/setup/export/DataExportPage/d'

profile = Selenium::WebDriver::Firefox::Profile.new
profile['browser.download.dir'] = Dir.pwd + '/backups'
profile["browser.download.dir"] = File.expand_path(__FILE__)
profile["browser.download.manager.showWhenStarting"] = false
profile["browser.helperApps.alwaysAsk.force"] =  false
profile['browser.helperApps.neverAsk.saveToDisk'] =  "application/zip;application/octet-stream;application/x-zip;application/x-zip-compressed"
agent = Watir::Browser.new :firefox, profile: profile
agent.goto(download_page)
agent.text_field(id: 'username' ).set cnf.fetch "username"
agent.text_field(id: 'password').set cnf.fetch "password"
agent.button(name: 'Login').click

agent.links(class: 'actionLink', text: 'download').each do |link|
  link.click
  sleep 60 * 12
end
