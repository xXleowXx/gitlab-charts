require 'net/http'

module ApiHelper
    def self.invoke_http_request(uri, request)
        response = Net::HTTP.start(uri.hostname, uri.port) {|http|
            http.request(request)
        }
    end
end
