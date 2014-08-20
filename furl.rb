# A sample Ruby program with basic HTTP calls to Fedora API. Sort of like cURL for Fedora. 
require "./fedora_api"

def show_syntax
  puts "Syntax:"
  puts "    furl get|createobj|createds|fixity full_path_to_object [options]"
  puts ""
  puts "To retrieve a node"
  puts "    furl get http://full/path/to/object"
  puts ""
  puts "To create an object"
  puts "    furl createobj [http://full/path/to/new/object]"
  puts ""
  puts "To create a datastream"
  puts "    furl createds http://full/path/to/new/datastream text_content"
  puts ""
  puts "To check fixity on a datastream"
  puts "    furl fixity http://full/path/to/object"
  puts ""
end


def print_response(response, include_body = true)
  puts "* Status: #{response.code}"
  puts "* Headers"
  headers = response.to_hash
  headers.each do |k,v| 
    puts "#{k} = #{v}"
  end
  if include_body
    puts "* Body"
    puts response.body
  end
end


action = ARGV[0]
response = nil
api = FedoraApi.new

if action == "get"
  object_url = ARGV[1]
  response = api.get_node(object_url) if object_url != nil
elsif action == "createds"
  object_url = ARGV[1]
  content = ARGV[2]
  if content != nil
    if content[0] == '@'
      # TODO 
      # we've received a file name, read its content
      # content = File.read(content)
    end
    response = api.create_datastream(object_url, content)
  end
elsif action == "createobj"
  object_url = ARGV[1]
  response = api.create_object(object_url)
elsif action == "fixity"
  object_url = ARGV[1]
  response = api.fixity(object_url) if object_url != nil
elsif action == "test"
  object_url = ARGV[1]
  response = api.test(object_url)
end

if response == nil
  show_syntax
else 
  print_response response
end

