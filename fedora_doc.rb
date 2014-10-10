# Helper class to capture details of a Fedora Resource from an HTTP response 
class FedoraDoc
  attr_reader :status, :headers, :body, :location

  def initialize(http_response)
    @status = http_response.code.to_i
    @headers = http_response.to_hash
    @body = http_response.body
    @location = http_response['location']
  end

end