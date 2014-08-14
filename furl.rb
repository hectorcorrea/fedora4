# A sample Ruby program with basic HTTP calls to Fedora API. Sort of like cURL for Fedora. 
# References: 
#    Fedora 4 REST API https://wiki.duraspace.org/display/FF/RESTful+HTTP+API
#    nethttp cheat sheet http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
require "net/http"
require "uri"

class FedoraApi

  def initialize(root_url = "http://localhost:8080/rest")
    @root_url = root_url
  end


  def get_node(object_url, format = "application/rdf+xml")
    uri = URI.parse(object_url)
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = format # application/rdf+xml or application/ld+json or text/plain
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(request)
    }
  end


  def create_datastream(url_path)
    timestamp = Time.now.to_s[0..18]
    uri = URI.parse(@root_url)
    # Both cases gives HTTP 415 (?)
    # if url_path == nil
    #   url = "#{uri.path}/fcr:content" 
    # else
    #   url = "#{uri.path}/#{url_path}?mixin=fedora:datastream"
    # end
    url = "#{uri.path}/#{url_path}/fcr:content"
    http = Net::HTTP.new(uri.hostname, uri.port)
    puts "HTTP PUT: #{url}"
    body = "Hello from Ruby at #{timestamp}"
    response = http.send_request("PUT", url, body)
  end


  def create_object(url_path)
    if url_path == nil
      # The new node's ID will be autogenerated and be available in the 
      # response (as a URL) in the location header and in the body of 
      # the response. Notice that we use HTTP POST for this.
      url = @root_url + "?mixin=fedora:object" 
      uri = URI.parse(url)
      puts "HTTP POST: #{url}"
      request = Net::HTTP::Post.new(uri)
      response = Net::HTTP.start(uri.hostname, uri.port) {|http|
        http.request(request)
      }
    else
      # Use the url_path as the new node ID.
      # Notice that we use HTTP PUT for this.
      uri = URI.parse(@root_url)
      http = Net::HTTP.new(uri.hostname, uri.port)
      url = "#{uri.path}/#{url_path}?mixin=fedora:object"
      puts "HTTP PUT: #{@root_url}#{url}"
      response = http.send_request("PUT", url)
    end
  end

  def test(url_path)
    uri = URI.parse(@root_url)
    http = Net::HTTP.new(uri.hostname, uri.port)
    url = "#{uri.path}/#{url_path}/fcr:content"
    puts "HTTP PUT: #{url}"
    body = "Hello from Ruby at #{Time.now.to_s[0..18]}"
    response = http.send_request("PUT", url, body)
  end

end


def show_syntax
  puts "Syntax:"
  puts "    furl action [options]"
  puts ""
  puts "To retrieve a node"
  puts "    furl get http://full/path/to/object"
  puts ""
  puts "To create an object"
  puts "    furl createobj [path/to/new/object]"
  puts ""
  puts "To create a datastream"
  puts "    furl createds path/to/new/object"
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
  id = ARGV[1]
  response = api.get_node(id) if id != nil
elsif action == "createds"
  url_path = ARGV[1]
  response = api.create_datastream(url_path)
elsif action == "createobj"
  url_path = ARGV[1]
  response = api.create_object(url_path)
elsif action == "test"
  response = api.test("testX")
end

if response == nil
  show_syntax
else 
  print_response response
end

