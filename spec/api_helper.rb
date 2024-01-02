require 'rest-client'
require 'json'

module ApiHelper
  BASE_URL = "https://gitlab-${CI_ENVIRONMENT_SLUG}.${KUBE_INGRESS_BASE_DOMAIN}/api/v4/".freeze
  # BASE_URL = "https://gitlab-gke122-review-tes-oetv01.cloud-native-v122.helm-charts.win/api/v4/"
  def self.invoke_get_request(uri)
    default_args = {
      method: :get,
      url: "#{BASE_URL}#{uri}",
      verify_ssl: true,
      headers: {
        # "Authorization" => "Bearer gplat-XXXX"
        "Authorization" => "#{GITLAB_ADMIN_TOKEN.to_s}"
      }
    }
    response = RestClient::Request.execute(default_args)
    puts response.to_s
    JSON.parse(response.body)
  end
end
