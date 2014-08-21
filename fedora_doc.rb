class FedoraDoc
  attr_reader :status, :headers, :body, :location

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

  def initialize(http_response, location = nil)
    # We shouldn't need to pass the location since we could fetch it from there HTTP headers or the body,
    # but for now this makes the code simpler.
    @status = http_response.code
    @headers = http_response.to_hash
    @body = http_response.body
    @location = location || http_response['location']
    # print_response http_response, false
  end

end