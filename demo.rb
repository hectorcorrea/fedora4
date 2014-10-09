# Runs through the basic functionality of the Fedora API class to 
# create an RDF source, attach a Non-RDF source to it, and fetch it.
require './fedora_api'


# Use a timestamp as the URI of our resources so that we get a new URI
# everytime we run this program. URI will look like "2014-10-09-15-45-22"
timestamp = Time.now.to_s[0..18]
timestamp_url = timestamp.gsub(':', '-').gsub(' ', '-')


# Point the Fedora API to our instance of Fedora.
fedora_url = "http://localhost:8080/rest"               # use this if you are using Fedora standalone
fedora_jetty_url = "http://localhost:8983/fedora/rest"  # use this if you are using Fedora through Hydra-Jetty
root_url = fedora_jetty_url
api = FedoraApi.new(root_url, true)


# Create a new RDF source (using the timestamp as the URI)
puts "=" * 50
new_doc = api.create_rdf timestamp_url

# Add a child non-RDF source (content) to our RDF source
puts "=" * 50
new_doc = api.create_non_rdf timestamp_url + "/content", "hello world"

# Display the information (in turtle) about the RDF source
puts "=" * 50
new_doc = api.get timestamp_url

# # Display the information (in turtle) about the non-RDF source
# # (this is possible but meaningless? maybe it makes to get version/fixity data)
# puts "=" * 50
# new_doc = api.get timestamp_url + "/content"

# Display the content of the non-RDF source
puts "=" * 50
new_doc = api.get_content timestamp_url + "/content"

# Display version information for the non-RDF source
puts "=" * 50
new_doc = api.versions timestamp_url + "/content"

# Display fixity information for the non-RDF source
puts "=" * 50
new_doc = api.fixity timestamp_url + "/content"



# # Run a Fixity check on the new datastream
# puts "=" * 50
# puts "Running a fixity check on #{datastream.location}..."
# fixity = api.fixity(datastream.location)
# puts "\tFixity result: "
# puts fixity.body[0..60] + "[truncated]"
# if fixity.body.include? ">SUCCESS<" 
#   puts "\tSUCCESS"
# else
#   puts "\tFAILURE"
# end
# puts

