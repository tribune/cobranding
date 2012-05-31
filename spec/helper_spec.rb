require File.expand_path('../spec_helper', __FILE__)

describe Cobranding::Helper do
  
  module Cobranding::Helper::TestMethods
    def content_for_cobranding
      "Content!"
    end
  end
  
  let(:view) do
    view = ActionView::Base.new
    view.extend(Cobranding::Helper::TestMethods)
    view
  end
  
  def template(rhtml)
    handler = ActionView::Template.handler_class_for_extension("erb")
    ActionView::Template.new(rhtml, "test template", handler, {})
  end
  
  def test_template(rhtml)
    handler = Template.handler_for_extension("erb")
    template = Template.new(rhtml, "test template", handler, {})
    template.extend(Cobranding::Helper)
    def template.content_for_cobranding
      "Content!"
    end
  end
  
  before :each do
    cache = ActiveSupport::Cache::MemoryStore.new
    Rails.stub!(:cache).and_return(cache)
  end
  
  it "should render a layout in a view with a Layout" do
    rhtml = '<%= cobranding_layout(layout) %>'
    layout = Cobranding::Layout.new("<html><title>Success</title><body>{{content}}</body></html>")
    view.stub(:layout => layout)
    view.render(:inline => rhtml).should == "<html><title>Success</title><body>Content!</body></html>"
  end
  
  it "should render a layout in a view with a Layout using custom prefix and suffix on helper methods" do
    def view._content!
      "Content with custom prefix/suffix"
    end
    url = "http://test.host/layout"
    rhtml = "<%= cobranding_layout('#{url}', :params => {:x => 1}, :prefix => '_', :suffix => '!') %>"
    layout = Cobranding::Layout.new("<html><title>Success</title><body>{{content}}</body></html>")
    Cobranding::Layout.should_receive(:get).with(url, :params => {:x => 1}).and_return(layout)
    view.stub(:layout => layout)
    view.render(:inline => rhtml).should == "<html><title>Success</title><body>Content with custom prefix/suffix</body></html>"
  end
  
  it "should render a layout in a view with a URL" do
    rhtml = '<%= cobranding_layout("http://localhost/layout", :params => {:v => 1}, :ttl => 300) %>'
    layout = Cobranding::Layout.new("<html><title>Success</title><body>{{content}}</body></html>")
    key = Cobranding::Layout.cache_key("http://localhost/layout?v=1")
    Rails.cache.write(key, layout)
    view.render(:inline => rhtml).should == "<html><title>Success</title><body>Content!</body></html>"
  end
  
  it "should render a layout in a view with an alternate failsafe layout in the body of the cobranding_layout tag" do
    rhtml = '<%= cobranding_layout("http://localhost/layout", :params => {:v => 1}, :ttl => 300) do -%><html><title>FAIL</title><body><%= content_for_cobranding %></body></html><% end -%>'
    layout = Cobranding::Layout.new("<html><title>Success</title><body>{{content}}</body></html>")
    key = Cobranding::Layout.cache_key("http://localhost/layout?v=1")
    Rails.cache.write(key, layout)
    view.render(:inline => rhtml).should == "<html><title>Success</title><body>Content!</body></html>"
  end
  
  it "should render a default layout in the body of the cobranding_layout tag in a view" do
    rhtml = '<%= cobranding_layout("invalid url", :params => {:v => 1}, :ttl => 300) do -%><html><title>FAIL</title><body><%= content_for_cobranding %></body></html><% end -%>'
    view.render(:inline => rhtml).should == "<html><title>FAIL</title><body>Content!</body></html>"
  end
  
  it "should raise an error if no failsafe layout is specified" do
    rhtml = '<%= cobranding_layout("http://localhost/layout", :params => {:v => 1}, :ttl => 300) %>'
    lambda{view.render(:inline => rhtml)}.should raise_error
  end
  
  context "when rendering a failsafe layout" do
    let(:action_view) { ActionView::Base.new }
    
    def block_helper(block, content)
      "<%= #{block} do %>#{content}<% end %>"
    end
    
    it "should render the default block only once when an exception is raised" do
      url = "http://p2p.cobranding.bad"
      expected_output = "Tribune Tower"
      Cobranding::Layout.should_receive(:get).with(url, nil).and_raise(Exception)
      
      output = action_view.render(:inline => block_helper(%(cobranding_layout("#{url}")), expected_output))
      output.should == expected_output
    end
  end
  
end
