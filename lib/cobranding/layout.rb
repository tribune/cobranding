# coding: utf-8
# NOTE this file should be in utf-8 encoding so #evaluate generates a string with
# this encoding. Otherwise on ruby 1.9 it'll be US-ASCII.
require 'erb'
require 'digest/md5'
require 'rest-client'

module Cobranding
  # This class is used to get layout HTML markup from a service and compile it into Ruby code that can be used
  # as the layout in a Rails view.
  class Layout
    QUOTED_RELATIVE_URL = /(<\w+\s((src)|(href))=(['"]))\/(.*?)(\5[^>]*?>)/i
    UNQUOTED_RELATIVE_URL = /(<\w+\s((src)|(href))=)\/(.*?)(>|(\s[^>]*?>))/i
    
    class << self
      # Get the layout HTML from a service. The options can be any of the options accepted by RestClient
      # or +:base_url+. Any relative URLs found in the HTML will be expanded to absolute URLs using either the
      # +:base_url+ option or the +url+ as the base.
      #
      # If +:ttl+ is specified in the options, the layout will be cached for that many seconds.
      #
      # By default the request will be a GET request. If you need to do a POST, you can pass :method => :post in the options.
      #
      # If a block is passed, it will be called with the layout html before the layout is created. This can be used
      # to munge the layout HTML code if necessary.
      def get (url, options = {}, &block)
        return nil if url.blank?
        options ||= {}
        options = options.is_a?(HashWithIndifferentAccess) ? options.dup : options.with_indifferent_access
        ttl = options.delete(:ttl)
        race_ttl = options.delete(:race_condition_ttl)
        if Rails.cache && ttl
          cache_options = {}
          cache_options[:expires_in] = ttl if ttl
          cache_options[:race_condition_ttl] = race_ttl if race_ttl
          key = cache_key(url, options)
          Rails.cache.fetch(key, cache_options) do
            layout = fetch_layout(url, options, &block)
          end
        else
          return fetch_layout(url, options, &block)
        end
      end

      # Generate a unique cache key for the layout request.
      def cache_key (url, options = {})
        options = options.is_a?(HashWithIndifferentAccess) ? options.dup : options.with_indifferent_access
        full_uri = full_uri(url, options)
        params = options.delete(:params)
        options.delete(:host)
        options.delete(:port)
        options.delete(:scheme)
        options.delete(:base)
        options.delete(:ttl)
        options.delete(:timeout)
        options.delete(:read_timeout)
        options.delete(:open_timeout)
        append_params_to_uri!(full_uri, params) if params
        
        options_key, query = full_uri.to_s.split('?', 2)
        if query
          options_key << '?'
          options_key << query.split('&').sort.join('&')
        end
        
        options.keys.sort{|a,b| a.to_s <=> b.to_s}.each do |key|
          options_key << " #{key}=#{options[key]}"
        end
        
        "#{name}.#{Digest::MD5.hexdigest(options_key)}"
      end
    
      protected
      
      # Fetch the layout HTML from the service. The block is optional and will be called with the html code.
      def fetch_layout (url, options, &block)
        method = options.delete(:method) || :get
        full_url = full_uri(url, options).to_s
        base_uri = options[:base_url] ? URI.parse(options.delete(:base_url)) : full_uri(url, options)
        base_uri.userinfo = nil
        base_uri.path = "/"
        base_uri.query = nil
        base_uri.fragment = nil
        response = method.to_sym == :post ? RestClient.post(full_url, options) : RestClient.get(full_url, options)
        html = expand_base_url(response, base_uri.to_s)
        html = block.call(html) if block
        layout = new(html)
      end
      
      # Expand any relative URL's found in HTML tags to be absolute URLs with the specified base.
      def expand_base_url (html, base_url)
        return html unless base_url
        base_url = "#{base_url}/" unless base_url.end_with?("/")
        html.gsub(QUOTED_RELATIVE_URL){|match| "#{$1}#{base_url}#{$6}#{$7}"}.gsub(UNQUOTED_RELATIVE_URL){|match| "#{$1}#{base_url}#{$5}#{$6}"}
      end
      
      private
      
      def full_uri (url, options)
        return url if url.kind_of?(URI)
        uri = URI.parse(url)
        base = URI.parse(options[:base]) if options[:base]

        if uri.scheme == nil
          host = options[:host]
          port = options[:port]
          scheme = options[:scheme]
          if base and base.scheme
            host ||= base.host
            port ||= base.port
            scheme ||= base.scheme
          end
          if host
            full_url = "#{scheme ? scheme : 'http'}://#{host}"
            full_url << ":#{port}" if port
            if base
              unless uri.to_s[0,1] == '/'
                full_url << base.path
                full_url << '/' unless base.path.last == '/'
              end
            end
            full_url << uri.to_s
            uri = URI.parse(full_url)
          end
        end

        return uri
      end

      def append_params_to_uri! (uri, params)
        unless params.blank?
          if uri.query.blank?
            uri.query = url_encode_parameters(params)
          else
            uri.query << "&"
            uri.query << url_encode_parameters(params)
          end
        end
      end

      def url_encode_parameters (params)
        params.collect{|name, value| url_encoded_param(name, value)}.join('&')
      end

      def url_encoded_param (name, value)
        if value.kind_of?(Array)
          return value.collect{|v| url_encoded_param(name, v)}.join('&')
        else
          return "#{Rack::Utils.escape(name.to_s)}=#{Rack::Utils.escape(value.to_s)}"
        end
      end
    end
    
    attr_accessor :src
    
    # Create the Layout. The src will be defined from the HTML passed in.
    def initialize (html = nil)
      self.html = html if html
    end
    
    # Set the src by compiling HTML into RHTML and then into Ruby code.
    def html= (html)
      self.src = compile(html)
    end

    # Evaluate the RHTML source code in the specified context. Any yields will call a helper method
    # corresponding to the value yielded if it exists. The options :prefix and :suffix can be set to
    # determine the full method name to call. The default is to suffix values with +_for_cobranding+
    # so that <tt>yield title</tt> will call +title_for_cobranding+. Setting a different prefix or
    # suffix can be useful if you are pulling in templates from different sources which use the same
    # variable names but need different values.
    def evaluate (context, options = nil)
      if src
        prefix = options[:prefix] if options
        suffix = options[:suffix] if options
        suffix = "_for_cobranding" unless prefix or suffix
        evaluator = Object.new
        # "src" is erb code, which contains the code `force_encoding(__ENCODING__)`.
        # __ENCODING__ is the current file's encoding (see magic comment above).
        eval <<-EOS
          def evaluator.evaluate
            #{src}
          end
        EOS
        evaluator.evaluate do |var|
          method = "#{prefix}#{var}#{suffix}"
          context.send(method) if context.respond_to?(method)
        end
      end
    end
    
    protected
    
    # Turn markup in the html into rhtml yield statments. Markup will be in HTML comments containing
    # listings:var where var is a variable name set using content_for.
    def rhtml (html)
      return nil unless html
      # Strip blank lines 'cuz theres just so many of them
      rhtml_code = html.gsub(/^\s+$/, "\n").gsub(/[\n\r]+/, "\n")
      # Escape things that look like ERB since it could be a mistake or it could be malicious
      rhtml_code.gsub!("<%", "&lt;%")
      rhtml_code.gsub!("%>", "%&gt;")
      # Replace special comments with yield tags.
      rhtml_code.gsub!(/\{\{\s*(\w+)\s*\}\}/){|match| "<%=yield :#{$1}%>"}
      return rhtml_code
    end

    # Compile RHTML into ruby code.
    def compile (html)
      ERB.new(rhtml(html), nil, '-').src.freeze if html
    end
  end
end
