# Runs through the basic functionality of the Fedora API class to 
# create an RDF source, attach a Non-RDF source to it, and fetch it.
require './fedora_api'

# Use a timestamp as the URI of our resources so that we get a new URI
# everytime we run this program. URI will look like "2014-10-09-15-45-22"
timestamp = Time.now.to_s[0..18]
timestamp_url = timestamp.gsub(':', '-').gsub(' ', '-')
book_url = 'book-' + timestamp_url


# Point the Fedora API to our instance of Fedora.
fedora_url = "http://localhost:8080/rest"               # use this if you are using Fedora standalone
fedora_jetty_url = "http://localhost:8983/fedora/rest"  # use this if you are using Fedora through Hydra-Jetty
root_url = fedora_jetty_url
verbose = true
api = FedoraApi.new(root_url, verbose)


puts "=" * 50
api.create_rdf book_url
api.update(book_url, "<http://whatever/title>", '""', '"Lord of the Rings"')
api.update(book_url, "<http://whatever/isbn>", '""', '"978-0618640157"')
api.get book_url

page1 = api.create_rdf book_url + "/page/1"
api.update(page1.location, "<http://whatever/number>", '""', '"1"')
api.update(page1.location, "<http://whatever/text>", '""', '"hi frodo"')

page2 = api.create_rdf book_url + "/page/2"
api.update(page2.location, "<http://whatever/number>", '""', '"2"')
api.update(page2.location, "<http://whatever/text>", '""', '"dude, is that mordor?"')

# page3 = api.create_rdf "page-3-" + timestamp_url
# api.update(page3.location, "<http://whatever/number>", '""', '"3"')
# api.update(page3.location, "<http://whatever/text>", '""', '"hello Gollum"')

# api.update(book_url, "<http://whatever/pages>", '""', "'" + page1.location + "'")
# api.update(book_url, "<http://whatever/pages>", '""', "'" + page2.location + "'")
# api.update(book_url, "<http://whatever/pages>", '""', "'" + page3.location + "'")



