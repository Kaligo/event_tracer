source "https://rubygems.org"

git_source(:ascenda_private) { |repo_name| ENV['BUNDLE_GITHUB__HTTPS'] ? "https://github.com/#{repo_name}.git" : "git@github.com:#{repo_name}.git" }

# Specify your gem's dependencies in event_tracer.gemspec
gemspec

group :test do
  gem 'aws-sdk-dynamodb'
  gem 'nokogiri'
  gem 'sidekiq'
  gem 'timecop'
  gem 'prometheus-client'
  gem 'pry-byebug'
end
