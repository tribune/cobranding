require File.expand_path('../spec_helper', __FILE__)

describe Cobranding::PersistentLayout do
  
  class Cobranding::PersistentLayout::Tester1
    attr_accessor :src, :url
    include Cobranding::PersistentLayout
  end
  
  class Cobranding::PersistentLayout::Tester2
    attr_accessor :layout_src, :layout_url, :layout_url_options
    include Cobranding::PersistentLayout
    self.layout_src_attribute = :layout_src
    self.layout_url_attribute = :layout_url
    self.layout_url_options_attribute = :layout_url_options
  end
  
  class Cobranding::PersistentLayout::Tester3
    attr_accessor :src, :url
    include Cobranding::PersistentLayout
    self.layout_preprocessor = lambda{|html| html.gsub('s', "$")}
  end
  
  class Cobranding::PersistentLayout::Tester4
    attr_accessor :src, :url
    include Cobranding::PersistentLayout
    self.layout_preprocessor = :replace_i
    
    def replace_i (html)
      html.gsub('i', '!')
    end
  end
  
  it "should fetch the layout and store the source into default fields" do
    model = Cobranding::PersistentLayout::Tester1.new
    model.url = "http://localhost/layout"
    layout = Cobranding::Layout.new("<html/>")
    Cobranding::Layout.should_receive(:get).with("http://localhost/layout", {}).and_return(layout)
    model.fetch_layout
    model.src.should == layout.src
    model.layout.should == layout
  end
  
  it "should fetch the layout and store the source into a specified fields" do
    model = Cobranding::PersistentLayout::Tester2.new
    model.layout_url = "http://localhost/layout"
    model.layout_url_options = {"params" => {"v" => 1}}
    layout = Cobranding::Layout.new("<html/>")
    Cobranding::Layout.should_receive(:get).with("http://localhost/layout", {"params" => {"v" => 1}}).and_return(layout)
    model.fetch_layout
    model.layout_src.should == layout.src
    model.layout.should == layout
  end
  
  it "should create a layout from the compiled source in the field" do
    model = Cobranding::PersistentLayout::Tester1.new
    layout = Cobranding::Layout.new("<html/>")
    model.src = layout.src
    model.layout.src.should == layout.src
    model.layout.object_id.should_not == layout.object_id
    model.layout.object_id.should == model.layout.object_id
  end
  
  context "fetching with preprocessor" do
    let(:url){ "http://localhost/layout" }
    before :each do
      stub_request(:get, url).to_return(:status => 200, :body => "This is a test")
    end
    
    it "should not invoke a preprocessor if it isn't defined" do
      model = Cobranding::PersistentLayout::Tester1.new
      model.url = url
      model.fetch_layout
      model.src.should == Cobranding::Layout.new("This is a test").src
    end
  
    it "should use a Proc as the layout preprocessor" do
      model = Cobranding::PersistentLayout::Tester3.new
      model.url = url
      model.fetch_layout
      model.src.should == Cobranding::Layout.new("Thi$ i$ a te$t").src
    end
    
    it "should use an instance method as the layout preprocessor" do
      model = Cobranding::PersistentLayout::Tester4.new
      model.url = url
      model.fetch_layout
      model.src.should == Cobranding::Layout.new("Th!s !s a test").src
    end
  end
  
  context "setting html with preprocessor" do    
    it "should not invoke a preprocessor if it isn't defined" do
      model = Cobranding::PersistentLayout::Tester1.new
      model.layout_html = "This is a test"
      model.src.should == Cobranding::Layout.new("This is a test").src
    end
  
    it "should use a Proc as the layout preprocessor" do
      model = Cobranding::PersistentLayout::Tester3.new
      model.layout_html = "This is a test"
      model.src.should == Cobranding::Layout.new("Thi$ i$ a te$t").src
    end
    
    it "should use an instance method as the layout preprocessor" do
      model = Cobranding::PersistentLayout::Tester4.new
      model.layout_html = "This is a test"
      model.src.should == Cobranding::Layout.new("Th!s !s a test").src
    end
  end
end
