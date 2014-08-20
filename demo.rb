require './fedora_api'

def print_response(response, include_body = true)
  puts "* Status: #{response.code}"
  puts "* Headers"
  headers = response.to_hash
  headers.each do |k,v| 
    puts "#{k} = #{v}"
  end
  if include_body
    puts "* Body"
    puts response.body
  end
end

fedora_url = "http://localhost:8080/rest"
timestamp = Time.now.to_s[0..18]
timestamp_url = fedora_url + "/" + timestamp.gsub(':', '-').gsub(' ', '-')

api = FedoraApi.new(fedora_url)
response = api.create_object timestamp_url 
print_response response