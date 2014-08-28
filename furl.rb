# A sample Ruby program with basic HTTP calls to Fedora API. Sort of like cURL for Fedora. 
require "./fedora_api"

def show_syntax
  puts "Syntax:"
  puts "    furl createobj|createds|get|getds|fixity|update|versions full_path_to_object [options]"
  puts ""
  puts "To create an object"
  puts "    furl createobj http://full/path/to/new/object"
  puts ""
  puts "To create a datastream"
  puts "    furl createds http://full/path/to/new/datastream text_content"
  puts ""
  puts "To retrieve a document or a datastream"
  puts "    furl get http://full/path/to/object"
  puts ""
  puts "To retrieve the content of a datastream"
  puts "    furl getds http://full/path/to/datastream"
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
  puts "Samples"
  puts '    furl createobj http://localhost:8080/rest/testDoc1'
  puts '    furl createds http://localhost:8080/rest/testDoc1/testDataSet1 "some text"'
  puts '    furl get http://localhost:8080/rest/testDoc1'
  puts '    furl get http://localhost:8080/rest/testDoc1/testDataSet1'
  puts '    furl getds http://localhost:8080/rest/testDoc1/testDataSet1'
  puts '    furl fixity http://localhost:8080/rest/testDoc1/testDataSet1'
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


action = ARGV[0]
object_url = ARGV[1]
doc = nil
api = FedoraApi.new

if action != nil && object_url != nil
  case action
  when "get"
    doc = api.get_node(object_url)
  when "getds"
    doc = api.get_content(object_url)
  when "createds"
    content = ARGV[2]
    doc = api.create_datastream(object_url, content) if content != nil
  when "createobj"
    doc = api.create_object(object_url)
  when "fixity"
    doc = api.fixity(object_url) 
  when "versions"
    doc = api.versions(object_url) 
  when "update"
    field = ARGV[2]
    old_value = ARGV[3]
    new_value = ARGV[4]
    if field != nil && old_value != nil && new_value != nil
      doc = api.update(object_url, field, old_value, new_value)
    end
  when "test"
    doc = api.test(object_url)
  end
end

if doc == nil
  show_syntax
else 
  print_doc doc
end

