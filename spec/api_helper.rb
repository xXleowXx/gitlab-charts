require 'net/http'

module ApiHelper
  def self.invoke_http_request(uri, request)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end
end
