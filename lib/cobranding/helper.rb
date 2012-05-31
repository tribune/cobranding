module Cobranding
  # This module gets mixed in to ActionView::Helpers so its methods are available in all Rails views.
  module Helper
    # Helper method to render a layout. The +url_or_layout+ can either be a URL to a layout service or a Layout object.
    # The options parameter will only be used if a URL is passed in.
    #
    # This method can take a block which should be a fail safe ERB version of the layout that will only be used if the
    # layout service is unavailable.
    #
    # Note that for Rails 2.x applications you must call the tag with a block as <% cobranding_layout do %> while in Rails 3.0
    # and later you must call it as <%= cobranding_layout do %>.
    def cobranding_layout (url_or_layout, options = nil, &block)
      options = options.dup if options
      evaluate_options = {:prefix => options.delete(:prefix), :suffix => options.delete(:suffix)} if options
      layout = url_or_layout.is_a?(Layout) ? url_or_layout : Layout.get(url_or_layout, options)
      layout.evaluate(self, evaluate_options).html_safe
    rescue SystemExit, Interrupt, NoMemoryError
      raise
    rescue Exception => e
      if block_given?
        Rails.logger.warn(e) if Rails.logger
        capture(&block).html_safe
      else
        raise e
      end
    end
  end
end
