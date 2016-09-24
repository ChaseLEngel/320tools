require 'rest-client'
require 'nokogiri'

if ARGV.length < 2
  puts "#{File.basename(__FILE__)} [assembly file] [output file]"
  exit
end

unless File.exists? ARGV[0]
  puts "File \"#{ARGV[0]}\" not found"
  exit
end

url = 'http://www.ecst.csuchico.edu/~kkredo/teaching/eece320/assembler/index.php'
file = File.new(ARGV[0], 'rb')

begin
  response = RestClient.post(url, {src_file: file})
rescue RestClient::Exception => error
  puts "Unable to contact site. #{error}"
  exit
end

page = Nokogiri::HTML(response)
# Grab text from third div on page. Assumed to always be assembled instructions.
instr_content = page.css('div#content')[2].text
# Remove header text, leading \n\t and ending \n
assembled = instr_content.tr('Memory initialization file contents', '').strip
File.new(ARGV[1], 'w').puts assembled
