# Runs through the basic functionality of the Fedora API class to 
# create a document, attach a datastream to it, and fetch it.
require './fedora_api'

fedora_url = "http://localhost:8080/rest"
timestamp = Time.now.to_s[0..18]
timestamp_url = fedora_url + "/" + timestamp.gsub(':', '-').gsub(' ', '-')
api = FedoraApi.new()


# Create a new document (using the timestamp as the URL)
puts "=" * 50
puts "Creating document..."
new_doc = api.create_object timestamp_url 
puts "\tDocument created #{new_doc.location}"
puts


# Fetch the new document
puts "=" * 50
puts "Fetching document #{new_doc.location}..."
doc = api.get_node(new_doc.location)
puts "\tDocument #{new_doc.location} fetched. Body: "
puts doc.body[0..60] + "...[truncated]"
puts


# Add a datastream (with content) to the new document
puts "=" * 50
puts "Adding a datastream to #{doc.location}..."
datastream = api.create_datastream(doc.location + "/datastream1", "Hello world at #{Time.now.to_s}")
puts "\tDatastream created at #{datastream.location}"
puts


# Fetch the datastream itself
puts "=" * 50
puts "Fetching datastream from #{datastream.location}..."
content = api.get_node(datastream.location)
puts "\tDatastream fetched. Body: "
puts content.body[0..60] + "...[truncated]"
puts


# Fetch the content of the atastream
puts "=" * 50
puts "Fetching content of datastream from #{datastream.location}..."
content = api.get_content(datastream.location)
puts "\tDatastream fetched. Body: "
puts content.body
puts


# Run a Fixity check on the new datastream
puts "=" * 50
puts "Running a fixity check on #{datastream.location}..."
fixity = api.fixity(datastream.location)
puts "\tFixity result: "
puts fixity.body[0..60] + "[truncated]"
if fixity.body.include? ">SUCCESS<" 
  puts "\tSUCCESS"
else
  puts "\tFAILURE"
end
puts

