require 'active_fedora'

class BookObject < ActiveFedora::Base
  property :title, predicate: ::RDF::DC.title
  property :isbn, predicate: ::RDF::URI.new('http://libraries.psu.edu/metadata/isbn')
end

# Create an object with a couple of properties
obj = BookObject.new( title: ["Lord of the Rings"], isbn: ["123-456-789"] )
obj.save
puts "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/#{obj.id}"

# Fetch it
obj2 = BookObject.find(obj.id)
puts obj2.title
puts obj2.isbn