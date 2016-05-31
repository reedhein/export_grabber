require 'nokogiri'
require 'mechanize'
require 'nokogiri'
require 'pry'
require 'pry-byebug'
require 'open-uri'
require 'selenium-webdriver'
require 'watir'
require 'active_support/time'

ActiveSupport::TimeZone[-8]

def work_hours?
    puts "work hours = #{17 < Time.now.hour && Time.now.hour > 9}"
    17 < Time.now.hour && Time.now.hour > 9
end

def hold_process
  puts 'waiting for work to be over'
  sleep 60
end

cnf = YAML::load(File.open('secrets.yml'))
# login_page    = 'https://login.salesforce.com/'
download_page = 'https://na34.salesforce.com/ui/setup/export/DataExportPage/d'
download_path = '/Users/voodoologic/Downloads'

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
sleep 6
file_names = Nokogiri::HTML(agent.html).search('.dataRow th').map(&:text)

def download_the_file(link, full_path)
  begin
    # hold_process while work_hours?
    link.click
    timer = 0
    while !file_downloaded?(full_path) do
      puts "waiting for file to finish"
      timer += 1
      sleep 60
    end
    puts "#{full_path} took #{timer} minutes to download"
  rescue => e
    puts e
    sleep 10
    retry
  end
end

def file_downloaded?(file_full_path)
  Pathname.new(file_full_path).exist? && !Pathname.new(file_full_path + '.part').exist? && File.open(file_full_path).size > 0
end

def remove_older(path)
  copy_count = 1
  copy_file_name = Pathname.new(path.split('.').join("(#{copy_count})."))
  FileUtils.rm(Pathname.new(path)) if Pathname.new(path).exist? || (Pathname.new(path).exist? && File.open(Pathname.new(path)).size == 0)
  FileUtils.rm(Pathname.new(path + ".part")) if Pathname.new(path + ".part").exist?
  while copy_file_name.exist? do
    puts "removing #{copy_file_name}"
    FileUtils.rm(copy_file_name)
    if Pathname.new(copy_file_name + ".part").exist?
      puts "removing #{copy_file_name + ".part"}"
      FileUtils.rm(Pathname.new(copy_file_name + ".part"))
    end
    copy_count += 1
  end
end

begin
  agent.links(class: 'actionLink', text: 'download').each_with_index do |link, i|
    f = file_names[i]
    full_path = download_path + '/' + f
    if file_downloaded?(full_path)
      puts "#{f} has already been downloaded"
    else
      puts "downloading #{f}"
      remove_older(full_path)
      download_the_file(link, full_path)
    end
  end
ensure
  agent.close
end

