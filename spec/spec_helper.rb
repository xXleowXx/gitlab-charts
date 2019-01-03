require 'aws-sdk-s3'
require 'open-uri'
require 'open3'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'
require 'gitlab_test_helper'

include Gitlab::TestHelper

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w(headless disable-gpu no-sandbox disable-dev-shm-usage) }
  )

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end

# From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
Capybara::Screenshot.register_driver(:headless_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

puts "SAVE PATH: #{::File.expand_path('../tmp/cabybara', __dir__)}"


Capybara.configure do |config|
  config.run_server = false
  config.default_driver = :headless_chrome
  config.app_host = gitlab_url
  config.save_path = ::File.expand_path('../tmp/cabybara', __dir__)
end

RSpec.configure do |config|
  config.include Capybara::DSL
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
