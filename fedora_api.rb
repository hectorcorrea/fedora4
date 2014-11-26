# Makes HTTP calls to Fedora REST API.
#
# References: 
#    [1] Fedora 4 REST API https://wiki.duraspace.org/display/FF/RESTful+HTTP+API
#    [2] nethttp cheat sheet http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
#
# The Fedora REST API is losely based on LDP (http://www.w3.org/TR/ldp/#fig-ldpr-class)
# and as such: 
#    a "RDF Source" represents a node in Fedora with RDF data
#    a "Non-RDF Source" represents a node in Fedora with "content" (e.g. the contents of a file)
#    a "resource" can either be an "RDF source" or a "Non-RDF Source":  
# 
require "net/http"
require "uri"
require "./fedora_doc.rb"
class FedoraApi

  HTTP_CREATED = 201
  HTTP_NO_CONTENT = 204


  # fedora_url is expected to be something like "http://localhost:8080/rest"
  # When verbose = true HTTP calls to Fedora are logged to stdout.
  def initialize(fedora_url, verbose = false) 
    @fedora_url = add_slash(fedora_url)
    @verbose = verbose
    #@default_model = "SomeFakeModel"
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
    if resource_uri == nil
      response = create_rdf_auto_id
    else
      response = create_rdf_custom_id resource_uri
    end
    doc = FedoraDoc.new(response)
    if doc.status == HTTP_CREATED
      log "RDF source created at #{doc.location}"
      enable_versioning doc.location
    else
      log "RDF source not created. HTTP status was #{doc.status}"
    end
    doc
  end


  # Creates a Non-RDF source in Fedora.
  # Non-RDF sources are used to represent content (text or binary)
  def create_non_rdf(new_resource_uri, content)
    # TODO: Add support for non-text data
    uri = build_uri_for_resource new_resource_uri    
    log "create_non_rdf at uri #{uri}"
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      request = Net::HTTP::Put.new(uri.path)
      request["Content-Type"] = "text/plain"
      request.body = content
      log request.body
      http.request(request)
    } 
    doc = FedoraDoc.new(response)    
    if doc.status == HTTP_CREATED || doc.status == HTTP_NO_CONTENT
      log "Non-RDF source created. Content available at #{doc.location}"
      enable_versioning new_resource_uri
    else
      log "Non-RDF source not created. HTTP status was #{doc.status}"
    end
    doc
  end


  # Fetches information about a resource (RDF or non-RDF) in Fedora.
  # For an RDF source the result will be the triples
  # For a non-RDF source the result will be the content (i.e. not the metadata) See get_metadata below.
  def get(resource_uri, format = "text/turtle")
    uri = build_uri_for_resource resource_uri     
    log "get #{uri}"
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = format
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(request)
    }
    doc = FedoraDoc.new(response)
    log "resource body \r\n#{doc.body}"
    doc
  end


  # Fetches metadata of a non-RDF source in Fedora.
  def get_metadata(resource_uri)
    log "get_metadata for #{resource_uri}"
    get "#{resource_uri}/fcr:metadata", "text/plain" 
  end


  # Returns fixity information for a non-RDF source
  # What happens if we call it for an RDF source(?)
  def fixity(resource_uri, format = "text/turtle")
    log "fixity for #{resource_uri}"
    get "#{resource_uri}/fcr:fixity", format
  end


  # Updates the value of a field in an RDF source in Fedora.
  # The update is done via an HTTP PATCH passing the field and
  # value to update via an SparQL update in the body of the request. 
  # 
  # Field must be in the form <http://whatever/field-name> 
  # Old value must be in quotes, e.g. "16801"
  # New value must be in quotes, e.g. "16802"
  def update(resource_uri, field, old_value, new_value)
    uri = build_uri_for_resource resource_uri 
    log "update for #{uri}"
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      request = Net::HTTP::Patch.new(uri.path)
      request["Content-Type"] = "application/sparql-update"
      request.body = <<-eos 
        PREFIX dc: <http://purl.org/dc/elements/1.1/>
        DELETE { <> #{field} #{old_value} . }
        INSERT { <> #{field} #{new_value} . }
        WHERE { }
      eos
      log request.body
      http.request(request)
    }    
    doc = FedoraDoc.new(response)
    if doc.status == HTTP_NO_CONTENT
      log "updated #{resource_uri}"
      enable_versioning resource_uri
    else
      log("update failed: \r\n" + http_response_to_s(response)) if doc.status != HTTP_NO_CONTENT
    end
    doc
  end


  # Returns version information for a resource 
  # In theory it should work for both RDF and non-RDF sources but 
  # at this point I am only enabling versions in create_non_rdf()
  def versions(resource_uri, format = "text/turtle")
    log "versions for #{resource_uri}"
    get "#{resource_uri}/fcr:versions", format
  end


  private 


  def add_slash(str)
    return str if str.end_with? "/"
    str + "/"
  end


  def build_uri_for_resource(resource_uri)
    if resource_uri.downcase.start_with? "http://"
      # Assume resource_uri is already a full URL to Fedora.
      uri = URI.parse("#{resource_uri}")
    else
      # Prepend the Fedora URL to the resource_uri.
      resource_uri = remove_first_slash(resource_uri)
      uri = URI.parse("#{@fedora_url + resource_uri}")
    end
    uri
  end


  def create_rdf_auto_id
    # Use HTTP POST
    # "Create a new automatically-named child node or datastream at the given path"[1]
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


  def create_rdf_custom_id(new_resource_uri)
    # Use HTTP PUT
    # "Create a resource with a specified path, or replace the triples associated with a resource with the triples provided in the request body."[1]
    uri = build_uri_for_resource new_resource_uri 
    log "create_rdf_custom_id at uri #{uri}"
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      request = Net::HTTP::Put.new(uri.path)
      title = "Sample RDF source created at #{Time.now.to_s} (#{rand(1000)})"
      request["Content-Type"] = "text/turtle"
      request.body = <<-eos 
        <> <http://purl.org/dc/elements/1.1/title> "#{title}" .
      eos
      log request.body
      http.request(request)
    }       
  end


  def enable_versioning(resource_uri)
    log "(skipping versioning code for now)"
    return
    uri = build_uri_for_resource resource_uri
    log "enable_versioning for #{uri}"
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      request = Net::HTTP::Post.new(uri.path+"/fcr:versions")
      http.request(request)
    } 
    if response.code.to_i == HTTP_NO_CONTENT
      log "version available at #{response['location']}"
    else
      log "Could not enable versioning\r\n" + http_response_to_s(response)
    end
    response
  end


  def http_response_to_s(response, include_body = true)
    headers = ""
    response.to_hash.each do |k,v| 
      headers += "#{k} = #{v}\r\n"
    end
    str = "* Status: #{response.code}\r\n* Headers\r\n#{headers}\r\n"
    if include_body
      str += "* Body\r\n #{response.body}\r\n"
    end
  end


  def log(text)
    puts "api: #{text}" if @verbose
  end


  def remove_first_slash(str)
    return str[1..-1] if str.start_with? "/"
    str
  end

end


