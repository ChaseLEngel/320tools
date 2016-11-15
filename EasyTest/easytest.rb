# This is a script to send assembly files to EECE 320 Tester website. 
# When an incorrect value is found the script with write the assembly file and the Tester html to a file.
# You will need to download EECE 320 Tester style.css for html to show colors.
# You must provide your own way to generate assembly files.
require 'restclient'
require 'nokogiri'
require 'optparse'
require 'digest'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} -l [logisim file] -i [iterations] -c [assembly generator command]"

  opts.on("-l=", "--logisim=", "Path to Logisim file.") do |l|
    options[:logisim] = l
  end

  opts.on("-i=", "--iterations=", "Number of files to test.") do |i|
    options[:iterations] = i.to_i
  end

  opts.on("-c=", "--command=", "Command to run to create assembly file.") do |c|
    options[:command] = c
  end
end.parse!

url = 'http://www.ecst.csuchico.edu/~kkredo/teaching/eece320/tester/index.php'

options[:iterations].times do
  # RestClient closes file after every request so we need to reopen it. Annoying...
  logisim_file = File.new(options[:logisim], 'rb')

  # Get assembly code
  generated = `#{options[:command]}`

  # Create file in memory
  assembly_file = StringIO.new(generated, "rb")

  md5 = Digest::MD5.new
  # Try to make sure we don't overwrite files.
  @filename = "#{md5.hexdigest(generated)[0...4]}.a"

  # Needed for restclient to treat StringIO as a File.
  def assembly_file.path
    "./#{@filename}"
  end

  begin
    response = RestClient.post(url, {assignment: 'lab4', logisim_file: logisim_file, assembly_file: assembly_file})
  rescue RestClient::Exception => error
    puts "Unable to contact site. #{error}"
    exit
  end

  # Parse HTML response
  page = Nokogiri::HTML(response)

  # Look for incorrect cell color in results.
  incorrect = page.css('#content').css('.results').css('.wrong_cell')

  # Write out assembly file if incorrect found.
  unless incorrect.empty?
    response_filename = @filename.gsub('.a', '.html')
    puts "Error found. Saving assembly and html to #{@filename} and #{response_filename}"
    incorrect_assembly_file = File.new(@filename, 'w')
    incorrect_assembly_file.puts(generated)
    incorrect_assembly_file.close
    response_file = File.new(response_filename, 'w')
    response_file.puts(response)
    response_file.close
  end

  logisim_file.close
end
