require File.expand_path('../spec_helper', __FILE__)

describe Cobranding::Layout do
  
  before :each do
    @context = Object.new
    def @context.test_tag_for_cobranding
      "Woo woo"
    end
    
    cache = ActiveSupport::Cache::MemoryStore.new
    Rails.stub!(:cache).and_return(cache)
  end

  it "should be able to evaluate a template from HTML" do
    layout = Cobranding::Layout.new("<html>Test</html>")
    layout.evaluate(@context).should == "<html>Test</html>"
  end

  it "should replace {{}} markup with predefined method calls" do
    layout = Cobranding::Layout.new("<html>Test {{test_tag}}</html>")
    layout.evaluate(@context).should == "<html>Test Woo woo</html>"
  end

  it "should replace {{}} markup with predefined method calls using a custom suffix" do
    def @context.test_tag_for_layout
      "custom suffix"
    end
    layout = Cobranding::Layout.new("<html>Test {{test_tag}}</html>")
    layout.evaluate(@context, :suffix => "_for_layout").should == "<html>Test custom suffix</html>"
  end

  it "should replace {{}} markup with predefined method calls using a custom prefix" do
    def @context.cobranding_test_tag
      "custom prefix"
    end
    layout = Cobranding::Layout.new("<html>Test {{test_tag}}</html>")
    layout.evaluate(@context, :prefix => "cobranding_").should == "<html>Test custom prefix</html>"
  end

  it "should replace {{}} markup with predefined method calls using a custom prefix and suffix" do
    def @context.cobranding_test_tag_for_layout
      "custom prefix and suffix"
    end
    layout = Cobranding::Layout.new("<html>Test {{test_tag}}</html>")
    layout.evaluate(@context, :prefix => "cobranding_", :suffix => "_for_layout").should == "<html>Test custom prefix and suffix</html>"
  end

  it "should ignore spaces in {{}} markup tags" do
    layout = Cobranding::Layout.new("<html>Test {{   test_tag  }}</html>")
    layout.evaluate(@context).should == "<html>Test Woo woo</html>"
  end

  it "should ignore method calls that are not defined" do
    layout = Cobranding::Layout.new("<html>Test {{no_tag}}</html>")
    layout.evaluate(@context).should == "<html>Test </html>"
  end

  it "should not allow malicious markup tags" do
    layout = Cobranding::Layout.new("<html>Test {{test_tag; File.read('/etc/passwd')}}</html>")
    layout.evaluate(@context).should == "<html>Test {{test_tag; File.read('/etc/passwd')}}</html>"
  end

  it "should strip extra new lines since they are stupid" do
    layout = Cobranding::Layout.new("<html>Test\r\n\t  \n Newline\n\n\n</html>")
    layout.evaluate(@context).should == "<html>Test\n Newline\n</html>"
  end

  it "should escape ERB code so evil things can't happen" do
    layout = Cobranding::Layout.new("<html>Test <%= File.read('/etc/passwd') %></html>")
    layout.evaluate(@context).should == "<html>Test &lt;%= File.read('/etc/passwd') %&gt;</html>"
  end
  
  it "should be able to get a layout from a URL" do
    stub_request(:get, "localhost/layout?site=1").to_return(:status => [200, "Success"], :body => "<html>{{test_tag}}</html>")
    layout = Cobranding::Layout.get("http://localhost/layout", :params => {:site => 1})
    layout.evaluate(@context).should == "<html>Woo woo</html>"
  end
  
  it "should be able to get a layout from URL components" do
    stub_request(:get, "https://localhost:444/layout/path?site=1").to_return(:status => [200, "Success"], :body => "<html>{{test_tag}}</html>")
    layout = Cobranding::Layout.get("path", :scheme => "https", :host => "localhost", :port => 444, :base => "/layout", :params => {:site => 1})
    layout.evaluate(@context).should == "<html>Woo woo</html>"
  end

  it "should be able to get a layout from a URL with a POST" do
    stub_request(:post, "localhost/layout").with(:params => {"site" => "1"}, :headers => {'Content-Type'=>'application/x-www-form-urlencoded'}).to_return(:status => [200, "Success"], :body => "<html>{{test_tag}}</html>")
    layout = Cobranding::Layout.get("http://localhost/layout", :method => :post, :site => 1)
    layout.evaluate(@context).should == "<html>Woo woo</html>"
  end
  
  it "should be able to get a layout from a URL without caching" do
    stub_request(:get, "localhost/layout?site=1").to_return(:status => [200, "Success"], :body => "<html>{{test_tag}}</html>")
    Rails.stub!(:cache).and_return(nil)
    layout = Cobranding::Layout.get("http://localhost/layout", :params => {:site => 1})
    layout.evaluate(@context).should == "<html>Woo woo</html>"
  end

  it "should generate consistent cache keys" do
    key_1 = Cobranding::Layout.cache_key("http://localhost/layout", :params => {:a => 1, :b => 2})
    key_2 = Cobranding::Layout.cache_key("http://localhost/layout", :params => {"a" => "1", "b" => "2"})
    key_3 = Cobranding::Layout.cache_key("http://localhost/layout?b=2&a=1")
    key_4 = Cobranding::Layout.cache_key("http://localhost/layout?b=1&a=2")
    key_5 = Cobranding::Layout.cache_key("http://localhost/layout_2", :params => {:a => 1, :b => 2})
    key_1.should == key_2
    key_1.should == key_3
    key_1.should_not == key_4
    key_1.should_not == key_5
  end
  
  it "should read a layout from the cache if it is found" do
    key = Cobranding::Layout.cache_key("http://localhost/layout")
    cached_layout = Cobranding::Layout.new("<html>Cached</html>")
    Rails.cache.write(key, cached_layout)
    layout = Cobranding::Layout.get("http://localhost/layout", :ttl => 300)
    layout.evaluate(@context).should == "<html>Cached</html>"
  end

  it "should not write a layout to the cache if :ttl is not specified" do
    stub_request(:get, "http://localhost/layout?v=1").to_return(:status => 200, :body => "<html>{{test_tag}}</html>")
    key = Cobranding::Layout.cache_key("http://localhost/layout", :params => {:v => 1})
    layout = Cobranding::Layout.get("http://localhost/layout", :params => {:v => 1})
    layout.evaluate(@context).should == "<html>Woo woo</html>"
    cached_layout = Rails.cache.read(key)
    cached_layout.should == nil
  end

  it "should expand relative URL's in the HTML based on the request URL" do
    html = "<a href=\"http://example.com/\"><img src=/logo.gif></a><A HREF='/test2'><IMG SRC=\"/images/new_logo.gif\" id=\"/logo\"></A>"
    stub_request(:get, "http://localhost/layout").to_return(:status => 200, :body => html)
    layout = Cobranding::Layout.get("http://localhost/layout")
    layout.evaluate(@context).should == "<a href=\"http://example.com/\"><img src=http://localhost/logo.gif></a><A HREF='http://localhost/test2'><IMG SRC=\"http://localhost/images/new_logo.gif\" id=\"/logo\"></A>"
  end

  it "should expand relative URL's in the HTML based on the :base_url option" do
    html = "<a href=\"http://example.com/\"><img src=/logo.gif></a><A HREF='/test2'><IMG SRC=\"/images/new_logo.gif\" id=\"/logo\"></A>"
    stub_request(:get, "http://localhost/layout").to_return(:status => 200, :body => html)
    layout = Cobranding::Layout.get("http://localhost/layout", :base_url => "https://secure.example.com/")
    layout.evaluate(@context).should == "<a href=\"http://example.com/\"><img src=https://secure.example.com/logo.gif></a><A HREF='https://secure.example.com/test2'><IMG SRC=\"https://secure.example.com/images/new_logo.gif\" id=\"/logo\"></A>"
  end
  
  it "should process the layout HTML with a block in case it needs to be munged" do
    html = 'this is <!--#include virtual="test_tag" --> stuff'
    stub_request(:get, "http://localhost/layout").to_return(:status => 200, :body => html)
    layout = Cobranding::Layout.get("http://localhost/layout") do |code|
      code.gsub('i', '!')
      code.gsub(/<!--#\s*include\s+virtual="([^"]+)"\s*-->/, '{{ \1 }}')
    end
    layout.evaluate(@context).should == "this is Woo woo stuff"
  end
end
