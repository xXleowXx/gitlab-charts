require 'gitlab'

class GitLabChartsHelper
  API_URL = ENV['GITLAB_API_URL'] || ENV['CI_API_V4_URL']
  CHARTS_PROJECT = ENV['CHARTS_PROJECT'] || ENV['CI_PROJECT_ID']

  class << self
    def supported_versions(count: 3)
      client = Gitlab::Client.new(endpoint: API_URL, private_token: ENV['CHARTS_DEV_PROJECT_TOKEN'])
      chart_release_tags = client.tags(CHARTS_PROJECT, search: '^v', per_page: 50)
      return unless chart_release_tags

      ordered_tag_names = chart_release_tags.map { |tag| tag.name.delete('v') }.sort_by { |v| Gem::Version.new(v) }.reverse
      latest_tag = nil
      supported_tags = []

      count.times do
        current_minor_series = latest_tag.nil? ? nil : latest_tag.split(".")[0..1].join(".")

        # @latest_tag has been already handled. Remove all the tags in that
        # series and get the remaining. In the first pass, nothing has been
        # already handled, so the entire list of tags is considered
        ordered_tag_names = ordered_tag_names.reject { |tag| tag.start_with?(current_minor_series) } if current_minor_series

        # Reset @latest_tag to the latest one in the remaining series
        latest_tag = ordered_tag_names.first
        supported_tags << latest_tag
      end

      supported_tags
    end
  end
end
