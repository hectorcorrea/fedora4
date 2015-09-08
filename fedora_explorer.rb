# Fetches all the object IDs in Fedora 4
require "net/http"
require "uri"

class FedoraExplorer

  def initialize(fedora_url, user, password)
    @fedora_url = fedora_url
    @user = user
    @password = password
  end

  # Walks the three of objects in Fedora starting at the root (@fedora_url)
  # The block is called after visiting each object and it receives an object
  # with information about the object (url, model, children count, et cetera.)
  def all_children &block
    raise "Must pass a block" unless block.respond_to?("call")
    get_children @fedora_url, block
  end

  def get_one(url)
    response = fedora_get_metadata url
    object = parse_triples response
    { url: url, model: object[:model], children: object[:children] }
  end

  private

  def get_children(url, block)
    # Fetch the given URL...
    start = Time.now
    response = fedora_get_metadata url
    time_ms = (Time.now - start) * 1000

    # ...parse its triples
    object = parse_triples response
    model = object[:model] || "nil"
    child_info = { url: url, model: model, time_ms: time_ms, size: response.length, children_count: object[:children].count }

    # ...let the caller know about this child
    block.call(child_info)

    # ...and then process its children recursively.
    object[:children].each do |child_url|
      get_children child_url, block
    end
  end

  # Response is an RDF graph in n-triple format and we expect it to have the
  # model of the object (e.g. GenericFile, Batch) as well a list of its children.
  #
  # The model comes in the form:
  #     <URI> <info:fedora/fedora-system:def/model#hasModel> "GenericFile"^^<http://www.w3.org/2001/XMLSchema#string> .
  #
  # Children come in the form:
  #     <URI> <http://www.w3.org/ns/ldp#contains> <CHILD-URI-1> .
  #     <URI> <http://www.w3.org/ns/ldp#contains> <CHILD-URI-2> .
  #
  def parse_triples response
    model = nil
    children = []
    start = Time.now
    response.split("\n").each do |line|
      tokens = line.split(" ")
      predicate = tokens[1]
      object = tokens[2]
      if predicate == "<info:fedora/fedora-system:def/model#hasModel>"
        # get the model of the object
        has_model = tokens[2]
        caret = object.index("^^")
        if caret
          model = has_model[0,caret].gsub('"', '')
        end
      elsif predicate == "<http://www.w3.org/ns/ldp#contains>"
        # get the list of children of the object
        child_url = tokens[2].gsub("<", "").gsub(">", "")
        children.push child_url
      end
    end
    {model: model, children: children}
  end

  def fedora_get_metadata(url)
    headers = { "Accept" => "application/n-triples" }
    uri = URI.parse(url  + "/fcr:metadata")
      response = Net::HTTP.start(uri.hostname, uri.port) { |http|
      request = Net::HTTP::Get.new(uri.path, headers)
      request.basic_auth(@user, @password)
      http.request(request)
    }
    response.body
  end

end

if ARGV.empty?
  # Assume localhost
  user = 'fedoraAdmin'
  password = 'fedoraAdmin'
  fedora_url = "http://localhost:8983/fedora/rest/dev"
elsif ARGV.count == 3
  # Use provided parameters
  user = ARGV[0]
  password = ARGV[1]
  fedora_url = ARGV[2]
else
  abort "Syntax: fedora_explorer user password URL"
end

fedora4 = FedoraExplorer.new(fedora_url, user, password)

count = 0
total_ms = 0
total_bytes = 0
puts "URI MODEL TIME_MS SIZE_B CHILD_COUNT"
fedora4.all_children do |child|
  count += 1
  total_ms += child[:time_ms]
  total_bytes += child[:size]
  puts "#{child[:url]} #{child[:model]} #{child[:time_ms].round(2)} #{child[:size]} #{child[:children_count]}"
end

puts
puts "total objects fetched: #{count}"
puts "           total time: #{total_ms.round(2)} ms"
puts "         average time: #{(total_ms / count).round(2)} ms"
puts "  total bytes fetched: #{total_bytes}"
