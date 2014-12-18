# The simplest example to write an object it Fedora 3 using just Ruby.
require "net/http"
require "uri"

user = 'fedoraAdmin'
password = 'fedoraAdmin'
url = "http://localhost:8983/fedora"

pid = "test:" + Random.rand(10000).to_s
label = "hello world"
puts "Creating object with PID #{pid}"

uri = URI.parse(url + "/objects/new")
response = Net::HTTP.start(uri.hostname, uri.port) {|http|
  request = Net::HTTP::Post.new(uri.path)
  request.basic_auth(user, password)
  request["Content-Type"] = "text/xml"
  request.body = <<-eos 
<?xml version="1.0" encoding="UTF-8"?>
<foxml:digitalObject VERSION="1.1" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
  xmlns:foxml="info:fedora/fedora-system:def/foxml#" 
  xsi:schemaLocation="info:fedora/fedora-system:def/foxml# 
  http://www.fedora.info/definitions/1/0/foxml1-1.xsd" 
  PID="#{pid}">
  <foxml:objectProperties><foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="A"/>
    <foxml:property NAME="info:fedora/fedora-system:def/model#label" VALUE="#{label}"/>
  </foxml:objectProperties>
</foxml:digitalObject>
  eos
  http.request(request)
}

puts response.inspect
puts response.body
puts "#{url}/objects/#{pid}"