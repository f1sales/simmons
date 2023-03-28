# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in simmons.gemspec
gem 'f1sales_custom-hooks', github: 'marciok/f1sales_custom-hooks', branch: 'master'
gem 'f1sales_helpers', github: 'f1sales/f1sales_helpers', branch: 'master'

gemspec

gem 'http'
gem 'rake', '~> 13.0'

group :development do
  gem 'rubocop', require: false
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'faker'
  gem 'rspec', '~> 3.0'
  gem 'webmock'
end
