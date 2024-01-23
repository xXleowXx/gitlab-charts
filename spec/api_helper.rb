require 'rest-client'
require 'json'

module ApiHelper
  # BASE_URL = "https://#{ENV['QA_ENVIRONMENT_URL']}/api/v4/".freeze
  BASE_URL= "http://gdk.test:3000/api/v4/".freeze
  def self.invoke_get_request(uri)
    puts "######################"
    puts BASE_URL.to_s
    default_args = {
      method: :get,
      url: "#{BASE_URL}#{uri}",
      verify_ssl: true,
      headers: {
        "Authorization" => "Bearer #{ENV['GITLAB_ADMIN_TOKEN']}"
      }
    }
    response = RestClient::Request.execute(default_args)
    puts "######################"
    puts JSON.parse(response.body).to_s
    JSON.parse(response.body)
  end
end
