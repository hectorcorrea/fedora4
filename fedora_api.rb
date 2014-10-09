# Makes HTTP calls to Fedora REST API.
#
# References: 
#    Fedora 4 REST API https://wiki.duraspace.org/display/FF/RESTful+HTTP+API
#    nethttp cheat sheet http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
#
# The Fedora REST API is losely based on LDP (http://www.w3.org/TR/ldp/#fig-ldpr-class)
# and as such: 
#    a "RDF Source" represents a node in Fedora with RDF data
#    a "Non-RDF Source" represents a node in Fedora with "content" (e.g. the contents of a file)
#    a "resource" can either be an "RDF source" or a "Non-RDF Source":  
# 
require "net/http"
require "uri"
require "digest/sha1"
require "./fedora_doc.rb"

class FedoraApi


  # fedora_url is expected to be something like "http://localhost:8080/rest"
  # When verbose = true HTTP calls to Fedora are logged to stdout.
  def initialize(fedora_url, verbose = false) 
    @fedora_url = add_slash(fedora_url)
    @verbose = verbose
    @default_model = "SomeFakeModel"
  end


  # Create is an alias for "create_rdf"
  def create(resource_uri = nil)
    create_rdf resource_uri
  end


  # Creates an RDF source in Fedora. 
  # If an resource_uri is given (e.g. "hello-world-123") the new source will be at this URI
  # (e.g. http://localhost/fedora:8080/rest/hello-world-123) otherwise we'll let Fedora
  # come up with its own URI and the new resource will be at 
  # http://localhost:8080/rest/some/long/path/decided/by/fedora.
  def create_rdf(resource_uri = nil)
    # TODO: Accept a variable set of properties
    # TODO: Could we create the document with versioning in one HTTP Call (?)
    # response2 = enable_versioning object_url
    if resource_uri == nil
      response = create_rdf_auto_id
    else
      response = create_rdf_custom_id resource_uri
    end
    doc = FedoraDoc.new(response)
    log "RDF resource created at #{doc.location}"
    doc
  end


  # Creates a non-RDF source in Fedora.
  # Non-RDF sources are used to represent content (text or binary)
  def create_non_rdf(new_resource_url, content)
    # TODO: Add support for non-text data
    new_resource_url = uri_to_id(new_resource_url)
    uri = URI.parse("#{@fedora_url + new_resource_url}")
    log "create_non_rdf at uri #{uri}"
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      request = Net::HTTP::Put.new(uri.path + "/fcr:content")
      request["Content-Type"] = "text/plain"
      request.body = content
      log request.body
      http.request(request)
    } 
    doc = FedoraDoc.new(response)    
    log "Non-RDF resource created at #{doc.location}"
    doc
  end


  # Fetches information about a resource (RDF or non-RDF) in Fedora.
  def get(resource_url, format = "text/turtle")
    uri = URI.parse("#{@fedora_url + resource_url}")
    log "get at #{uri}"
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = format
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(request)
    }
    doc = FedoraDoc.new(response)
    log "resource body \r\n#{doc.body}"
    doc
  end


  # Fetches content of a non-RDF source in Fedora.
  def get_content(resource_url)
    log "get_content for #{resource_url}"
    get "#{resource_url}/fcr:content", "text/plain" 
  end


  def fixity(object_url, format = "application/rdf+xml")
    response = get_extra object_url, "fcr:fixity", format
    FedoraDoc.new(response)    
  end


  def versions(object_url, format = "application/rdf+xml")
    response = get_extra object_url, "fcr:versions", format
    FedoraDoc.new(response)
  end


  def update(object_url, field, old_value, new_value)
    uri = URI.parse("#{object_url}")
    # puts "HTTP PUT: #{object_url}"
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      dublinCorePrefix = 'PREFIX dc: <http://purl.org/dc/elements/1.1/>' + "\r\n"
      customFieldsPrefix = 'PREFIX xyz: <http://xyz.com/xyz/elements/1.1/>' + "\r\n"
      request = Net::HTTP::Patch.new(uri.path)
      request["Content-Type"] = "application/sparql-update"
      request.body = dublinCorePrefix
      request.body += customFieldsPrefix
      request.body += 'DELETE { ' + "\r\n"
      request.body += '  <> ' + field + ' "' + old_value + '" .' + "\r\n"
      request.body += '}' + "\r\n"
      request.body += 'INSERT { ' + "\r\n"
      request.body += '  <> ' + field + ' "' + new_value + '" .' + "\r\n"
      request.body += '}' + "\r\n"
      request.body += 'WHERE { }' + "\r\n"
      http.request(request)
    }    
    FedoraDoc.new(response)
  end


  private 


  def add_slash(str)
    return str if str.end_with? "/"
    str + "/"
  end


  def remove_first_char(str)
      str[1..-1]
  end


  def uri_to_id(uri)
    return remove_first_char(uri) if uri.start_with? "/"
    uri 
  end


  def log(text)
    puts "api: #{text}" if @verbose
  end


  def create_rdf_auto_id
    # Use HTTP POST
    # "Create a new automatically-named child node or datastream at the given path"
    uri = URI.parse("#{@fedora_url}")
    log "create_rdf_auto_id at uri #{uri}"
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      request = Net::HTTP::Post.new(uri.path)
      title = "Sample RDF source created at #{Time.now.to_s} (#{rand(1000)})"
      request["Content-Type"] = "text/turtle"
      request.body = <<-eos 
        <> <http://purl.org/dc/elements/1.1/title> "#{title}" .
      eos
      log request.body
      http.request(request)
    }  
  end  


  def create_rdf_custom_id(new_resource_url)
    # Use HTTP PUT
    # "Create a resource with a specified path, or replace the triples associated with a resource with the triples provided in the request body."
    new_resource_url = uri_to_id(new_resource_url)
    uri = URI.parse("#{@fedora_url + new_resource_url}")
    log "create_rdf_custom_id at uri #{uri}"
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      request = Net::HTTP::Put.new(uri.path)
      title = "Sample RDF source created at #{Time.now.to_s} (#{rand(1000)})"
      request["Content-Type"] = "text/turtle"
      # request.body = <<-eos 
      #   <> <http://fedora.info/definitions/v4/rels-ext#hasModel> "#{@default_model}" ;
      #      <http://purl.org/dc/elements/1.1/title> "#{title}" .
      # eos
      request.body = <<-eos 
        <> <http://purl.org/dc/elements/1.1/title> "#{title}" .
      eos
      log request.body
      http.request(request)
    }       
  end

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

end


