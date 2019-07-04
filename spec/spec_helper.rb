require 'aws-sdk-s3'
require 'open-uri'
require 'open3'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'
require 'rspec/retry'
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

# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run

# From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
Capybara::Screenshot.register_driver(:headless_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara.configure do |config|
  config.run_server = false
  config.default_driver = :headless_chrome
  config.app_host = gitlab_url
  config.save_path = ::File.expand_path('../tmp/capybara', __dir__)
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

  config.define_derived_metadata(file_path: %r{/spec/features/}) do |metadata|
    metadata[:type] = :feature
  end

  # show retry status in spec process
  # show exception that triggers a retry if verbose_retry is set to true
  config.verbose_retry = true
  config.display_try_failure_messages = true

  config.around do |example|
    example.run_with_retry retry: 2
  end
end
