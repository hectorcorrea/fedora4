# A sample Ruby program with basic HTTP calls to Fedora API. Sort of like cURL for Fedora. 
require "./fedora_api"

def show_syntax
  puts "Syntax:"
  puts "    furl create|createcontent|get|getcontent|fixity|update|versions full_path_to_object [options]"
  puts ""
  puts "To create an RDF source"
  puts "    furl create fedora_url path/to/new/rdf-source"
  puts ""
  puts "To create a Non-RDF source (e.g. content)"
  puts "    furl createcontent fedora_url path/to/new/non-rdf-source content"
  puts ""
  puts "To retrieve an RDF source"
  puts "    furl get fedora_url path/to/existing/rdf-source"
  puts ""
  puts "To retrieve the content of a Non-RDF source"
  puts "    furl getcontent fedora_url path/to/existing/non-rdf-source"
  puts ""
  puts "To check fixity on a datastream"
  puts "    furl fixity http://full/path/to/object"
  puts ""
  puts "To get versions of a document or datastrea"
  puts "    furl versions http://full/path/to/object"
  puts ""
  puts "To update a field in a document. The field_name must include the namespace (e.g. dc:title)"
  puts "    furl update http://full/path/to/object field_name old_value new_value"
  puts ""
  puts ""
  puts "Samples (assuming Fedora 4 is running on http://localhost:8080/rest)"
  puts ""
  puts '    furl http://localhost:8080/rest create my-new-rdf-source'
  puts '    furl http://localhost:8080/rest createcontent my-new-rdf-myrdf/content "some text"'
  puts '    furl http://localhost:8080/rest get my-new-rdf-source'
  puts '    furl http://localhost:8080/rest getcontent my-new-rdf-myrdf/content'
  puts '    furl http://localhost:8080/rest fixity http://localhost:8080/rest/testDoc1/testDataSet1'
  puts ""
end


def print_doc(doc, include_body = true)
  puts "HTTP Status: #{doc.status}"
  puts "Location: #{doc.location}" if doc.location
  if include_body && doc.body && doc.body.chomp.length > 0
    puts "Fedora Body:"
    puts doc.body
  end
end


fedora_url = ARGV[0] || ""
action = ARGV[1]
resource_uri = ARGV[2]
doc = nil
api = FedoraApi.new(fedora_url, true)

if action != nil && resource_uri != nil
  case action
  when "create"
    doc = api.create resource_uri
  when "createcontent", "createc"
    content = ARGV[3]
    doc = api.create_non_rdf(resource_uri, content) if content != nil
  when "get"
    doc = api.get resource_uri
  when "getcontent", "getc"
    doc = api.get_content resource_uri
  when "fixity"
    doc = api.fixity(resource_uri) 
  when "versions"
    doc = api.versions(resource_uri) 
  when "update"
    field = ARGV[2]
    old_value = ARGV[3]
    new_value = ARGV[4]
    if field != nil && old_value != nil && new_value != nil
      doc = api.update(resource_uri, field, old_value, new_value)
    end
  when "test"
    doc = api.test(resource_uri)
  end
end

if doc == nil
  show_syntax
else 
  print_doc doc
end

