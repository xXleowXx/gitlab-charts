source 'https://rubygems.org'

group :test do
  gem 'rspec'
  gem 'rspec-retry'
  gem 'rspec-parameterized', require: false
  gem 'aws-sdk-s3', '>= 1.120'
  gem 'capybara'
  gem 'docker-api'
  gem 'rake'
  gem 'hash-deep-merge'
  gem 'knapsack'
  gem 'tomlrb'
  gem 'fugit'
  gem 'rest-client'
end

group :rubocop do
  gem 'gitlab-styles', '~> 9.0', require: false
end

group :development, :test do
  gem 'pry'
end

group :development, :test, :danger do
  gem 'gitlab-dangerfiles', '~> 3.12.0', require: false
end

group :development do
  gem 'solargraph'
end
