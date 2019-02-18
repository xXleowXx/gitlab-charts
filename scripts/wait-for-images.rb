#!/usr/bin/env ruby

require 'yaml'
require 'net/http'
require 'json'
require 'cgi'

# IDs of each registry repository in gitlab-org/build/CNG project
repositories = {
  'sidekiq': 89804,
  'workhorse': 136859,
  'unicorn': 89806,
  'gitaly': 47854,
  'task-runner': 89819,
  'mailroom': 137282
}

CI_API_V4_URL = ENV['CI_API_V4_URL'].freeze || "https://gitlab.com/api/v4".freeze
PROJECT_PATH = "gitlab-org/build/CNG".freeze
INTERVAL = 300 # 5 minute
TIMEOUT = 1800 # 30 minute
CHARTS_VERSION = YAML.load_file('Chart.yaml')['appVersion'].strip.freeze

repositories.each do |component, id|
  uri = URI("#{CI_API_V4_URL}/projects/#{CGI.escape(PROJECT_PATH)}/registry/repositories/#{id}/tags/v#{CHARTS_VERSION}")
  start = Time.now.to_i

  print "\nWaiting for #{component}: "
  loop do
    raise "Timed out waiting for #{component}" if (Time.now.to_i > (start + TIMEOUT))

    req = Net::HTTP::Get.new(uri)
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.code == '404'
      print "."
      sleep INTERVAL
    elsif res.code == '200'
      print "Found"
      break
    end

    STDOUT.flush
  end
end
