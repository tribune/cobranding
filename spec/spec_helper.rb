require 'rubygems'
require 'logger'
require 'webmock/rspec'
rails_version = ENV["RAILS_VERSION"] || ">=3.0.5"
gem 'activesupport', rails_version
gem 'actionpack', rails_version
begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError
  # simplecov not installed
end

WebMock.disable_net_connect!

require File.expand_path('../../lib/cobranding', __FILE__)


module Rails
end

def Rails.env
  "test"
end

def Rails.cache
  @cache ||= ActiveSupport::Cache::MemoryStore.new
end

def Rails.logger
  @logger ||= Logger.new(StringIO.new)
end
