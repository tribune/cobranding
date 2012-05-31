require 'active_support/all' unless defined?(ActiveSupport::HashWithIndifferentAccess)
require 'action_view'
require 'rack'

module Cobranding
  require File.join(File.expand_path(File.dirname(__FILE__)), 'cobranding', 'layout')
  require File.join(File.expand_path(File.dirname(__FILE__)), 'cobranding', 'helper')
  autoload :PersistentLayout, File.join(File.expand_path(File.dirname(__FILE__)), 'cobranding', 'persistent_layout')
  
  ActionView::Base.send(:include, Helper)
end
