module Cobranding
  # This module can be mixed in to persistent objects so that layouts can be persisted to a data store. This is very
  # useful when there are only a few layouts and they don't need to be updated in real time. In this case, you can run
  # a background task to call fetch_layout on all your persistent layouts to update them asynchronously.
  #
  # By default, it will be assumed that the URL for the layout service will be stored in a field called +url+ and
  # the compiled Layout ruby code will be stored in +src+. You can override these values with +layout_src_attribute+
  # and +layout_url_attriubte+. In addition, if the URL takes options, you can specify the field that stores the Hash
  # with +layout_url_options_attribute+.
  #
  # If the layout code needs to be munged, set the +:layout_preprocessor+ class attribute to either a symbol that
  # matches a method name or to a +Proc+.
  module PersistentLayout
    def self.included (base)
      base.class_attribute :layout_src_attribute, :layout_url_attribute, :layout_url_options_attribute, :layout_preprocessor
    end
    
    # Fetch a loyout from the service and store the ruby src code in the src attribute.
    def fetch_layout
      layout_url = send(layout_url_attribute || :url)
      unless layout_url.blank?
        options = send(layout_url_options_attribute) unless layout_url_options_attribute.blank?
        options ||= {}
        preprocessor = self.class.layout_preprocessor
        if preprocessor && !preprocessor.is_a?(Proc)
          preprocessor = method(preprocessor)
        end
        @layout = preprocessor ? Layout.get(layout_url, options, &preprocessor) : Layout.get(layout_url, options)
        send("#{self.class.layout_src_attribute || :src}=", @layout.src)
      end
    end
    
    # Get the layout defined by the src attribute.
    def layout
      unless @layout
        layout_src = send(layout_src_attribute || :src)
        unless layout_src.blank?
          @layout = Layout.new
          @layout.src = layout_src
        end
      end
      @layout
    end
    
    def layout_html= (html)
      preprocessor = self.class.layout_preprocessor
      preprocessor = method(preprocessor) if preprocessor && !preprocessor.is_a?(Proc)
      html = preprocessor.call(html) if preprocessor
      @layout = Layout.new(html)
      send("#{self.class.layout_src_attribute || :src}=", @layout.src)
    end
  end
end
