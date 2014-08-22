# References: 
#    Fedora 4 REST API https://wiki.duraspace.org/display/FF/RESTful+HTTP+API
#    nethttp cheat sheet http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
require "net/http"
require "uri"
require "digest/sha1"
require "./fedora_doc.rb"

class FedoraApi

  def get_node(object_url, format = "application/rdf+xml")
    uri = URI.parse(object_url)
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = format # application/rdf+xml or application/ld+json or text/plain
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(request)
    }
    FedoraDoc.new(response, object_url)
  end


  def get_content(object_url, format = "application/rdf+xml")
    get_node "#{object_url}/fcr:content", format
  end


  def create_datastream(object_url, text_content, calculate_sha1 = false)
    # TODO: create proper HTTP request for multi-part binary data
    uri = URI.parse("#{object_url}")
    url = "#{uri.path}/fcr:content"
    if calculate_sha1
      # Fedora will calculate a SHA1 automatically. Passing a SHA1 value
      # is good only if you want to make sure the content was transfered 
      # pristine over the network to Fedora itself.  
      sha1 = Digest::SHA1.hexdigest text_content
      url += "?checksum=urn:sha1:#{sha1}"
    end
    http = Net::HTTP.new(uri.hostname, uri.port)
    # puts "HTTP PUT: #{url}"
    response = http.send_request("PUT", url, text_content)
    # TODO: Could we create the document with versioning in one HTTP Call (?)
    response2 = enable_versioning object_url
    FedoraDoc.new(response, object_url)
  end


  def create_object(object_url)
    # if object_url == nil
    #   # The new node's ID will be autogenerated and be available in the 
    #   # response (as a URL) in the location header and in the body of 
    #   # the response. Notice that we use HTTP POST for this.
    #   url = @root_url + "?mixin=fedora:object" 
    #   uri = URI.parse(url)
    #   puts "HTTP POST: #{url}"
    #   request = Net::HTTP::Post.new(uri)
    #   response = Net::HTTP.start(uri.hostname, uri.port) {|http|
    #     http.request(request)
    #   }
    # end
    # TODO: Accept a variable set of properties
    response = create_object_with_properties object_url
    # TODO: Could we create the document with versioning in one HTTP Call (?)
    response2 = enable_versioning object_url
    FedoraDoc.new(response)
  end


  def fixity(object_url, format = "application/rdf+xml")
    response = get_extra object_url, "fcr:fixity", format
    FedoraDoc.new(response)    
  end


  def versions(object_url, format = "application/rdf+xml")
    response = get_extra object_url, "fcr:versions", format
    FedoraDoc.new(response)
  end


  def test(object_url, format = "application/rdf+xml")
  end


  private 

  def get_extra(object_url, extra, format)
    uri = URI.parse("#{object_url}/#{extra}")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = format # application/rdf+xml or application/ld+json or text/plain
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(request)
    }
  end

  def enable_versioning(object_url)
    uri = URI.parse("#{object_url}")
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      request = Net::HTTP::Post.new(uri.path+"/fcr:versions")
      http.request(request)
    } 
  end

  def create_object_with_properties(object_url)
    uri = URI.parse("#{object_url}")
    # puts "HTTP PUT: #{object_url}"
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      request = Net::HTTP::Put.new(uri.path)
      # this does not work
      # request["Content-Type"] = "text/plain"
      # request.body = 'hello'

      # this works
      # request["Content-Type"] = "text/turtle"
      # request.body = 'PREFIX dc: <http://purl.org/dc/elements/1.1/>' + "\r\n" + '<> dc:title "some-resource-title" .'

      # this works 
      title = "Sample object created at #{Time.now.to_s}"
      request["Content-Type"] = "application/rdf+xml"
      request.body = '<?xml version="1.0" encoding="UTF-8"?>' + "\r\n"
      request.body += '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">' + "\r\n"
      request.body += '<rdf:Description rdf:about="">' + "\r\n"
      request.body += '<title xmlns="http://purl.org/dc/elements/1.1/" rdf:datatype="http://www.w3.org/2001/XMLSchema#string">' + title + '</title>' + "\r\n"
      request.body += '</rdf:Description>' + "\r\n"
      request.body += '</rdf:RDF>' + "\r\n"
      http.request(request)
    }    
  end

end


