require File.expand_path('../../test_helper', __FILE__)

$WEBAPP_DEBUG = false

class Hash
  def getNamedItem(item)
    self[item]
  end
end

class String
  def value
    self
  end
end

module EventHandlerSpecHelper
  def stub_webview
    @webView = stub('WebView')
    
    @doc = stub('DOMDocument')
    @doc.stubs(:addEventListener___)
    
    @webView.stubs(:mainFrame).returns(@webView)
    @webView.stubs(:DOMDocument).returns(@doc)
    
    @dataSource = stub('DataSource')
    @webView.stubs(:dataSource).returns(@dataSource)
    
    @handler.webView = @webView
    
    @url, @title = 'http://www.example.com/home', 'home page'
    stub_url_and_title(@url, @title)
  end
  
  private
  
  def stub_url_and_title(url, title)
    @doc.stubs(:URL).returns(url)
    @doc.stubs(:title).returns(title)
    @dataSource.stubs(
      :request => @dataSource,
      :URL => @dataSource,
      :absoluteString => url
    )
  end
end

class TestEventHandler < WebApp::EventHandler
  HOME = /\/home$/
  
  # only for urls that end with "/home"
  on_page_loaded(HOME) do |url, title|
    home_page_did_load(url, title)
  end
  
  # for all urls
  on_page_loaded do |url, title|
    any_page_did_load(url, title)
  end
  
  # only for urls that end with "/home"
  on_event('DOMNodeInserted', :url => HOME) do |event, node|
    DOMNodeInserted_on_home_page(event, node)
  end
  
  # for all urls
  on_event('DOMNodeInserted', :conditions => { :class => 'some_class' }) do |event, node|
    DOMNodeInserted_on_any_page(event, node)
  end
  
  on_event('DOMNodeInserted', :conditions => { :class => 'some_class' }) do |event, node|
    DOMNodeInserted_on_any_page(event, node)
  end
  
  on_event('DOMNodeInserted', :conditions => { :id => 'some_id', :class => 'some_class' }) do |event, node|
    DOMNodeInserted_on_any_page_with_specific_id(event, node)
  end
  
  on_event('NoRealEvent', :conditions => { :class => 'some_class' }) do |event, node|
    should_not_be_called(event, node)
  end
  
  def home_page_did_load(url, title); end
  def any_page_did_load(url, title); end
  def should_not_be_called(event, node); end
  def DOMNodeInserted_on_home_page(event, node); end
  def DOMNodeInserted_on_any_page(event, node); end
  def DOMNodeInserted_on_any_page_with_specific_id(event, node); end
end

describe "EventHandler, when setting up" do
  before do
    @handler = TestEventHandler.alloc.init
  end
  
  it "should define a on_page_loaded instance method" do
    mname = 'event_handler_method_1'
    options = TestEventHandler.ivar(:event_handlers)[0]
    @handler.private_methods.should.include mname
    options[:name].should == 'WebAppPageDidLoad'
    options[:event_handler_method].should == mname.to_sym
    options[:options].should == { :url => /\/home$/, :conditions => {}}
    
    mname = 'event_handler_method_2'
    options = TestEventHandler.ivar(:event_handlers)[1]
    @handler.private_methods.should.include mname
    options[:name].should == 'WebAppPageDidLoad'
    options[:event_handler_method].should == mname.to_sym
    options[:options].should == { :url => nil, :conditions => {}}
  end
  
  it "should define event handler instance methods" do
    mname = 'event_handler_method_3'
    options = TestEventHandler.ivar(:event_handlers)[2]
    
    @handler.private_methods.should.include mname
    options[:name].should == 'DOMNodeInserted'
    options[:event_handler_method].should == mname.to_sym
    options[:options].should == { :url => /\/home$/, :conditions => {}}
  end
end

describe "EventHandler, when a page has been loaded" do
  include EventHandlerSpecHelper
  
  before do
    @handler = TestEventHandler.alloc.init
    stub_webview
  end
  
  it "should register event handlers with the document if options[:url] matches" do
    @doc.expects(:addEventListener___).times(2).with('DOMNodeInserted', @handler, true)
    @handler.expects(:home_page_did_load).times(1).with(@url, @title)
    @handler.expects(:any_page_did_load).times(1).with(@url, @title)
    
    @handler.register_dom_observers!
  end
  
  it "should not register event handlers with a document if the url doesn't match" do
    url, title = 'http://www.example.com/not_home', 'not the home page'
    stub_url_and_title(url, title)
    
    @doc.expects(:addEventListener___).times(1).with('DOMNodeInserted', @handler, true)
    @handler.expects(:home_page_did_load).times(0)
    @handler.expects(:any_page_did_load).times(1).with(url, title)
    
    @handler.register_dom_observers!
  end
  
  it "should handle other real DOM events" do
    @handler.register_dom_observers!
    
    event, node = stub('Event'), stub('Node')
    event.stubs(:relatedNode => node, :objc_send => 'DOMNodeInserted')
    node.stubs(:outerHTML => 'foo')
    
    node.stubs(:attributes => { 'class' => 'some_class' })
    @handler.expects(:DOMNodeInserted_on_home_page).times(1)
    @handler.expects(:DOMNodeInserted_on_any_page).times(2)
    @handler.expects(:DOMNodeInserted_on_any_page_with_specific_id).times(0)
    @handler.expects(:should_not_be_called).times(0)
    @handler.handleEvent(event)
    
    node.stubs(:attributes => { 'id' => 'some_id', 'class' => 'some_class' })
    @handler.expects(:DOMNodeInserted_on_home_page).times(1)
    @handler.expects(:DOMNodeInserted_on_any_page).times(2)
    @handler.expects(:DOMNodeInserted_on_any_page_with_specific_id).times(1)
    @handler.expects(:should_not_be_called).times(0)
    @handler.handleEvent(event)
  end
end

GLOBAL_URL = /\/home$/
SOME_OTHER_PAGE_URL = /\/some_other_page$/

class GlobalUrlEventHandler < WebApp::EventHandler(GLOBAL_URL)
  on_page_loaded(SOME_OTHER_PAGE_URL) do |url, title|
    other_page_did_load(url, title)
  end
  
  on_page_loaded do |url, title|
    home_page_did_load(url, title)
  end
  
  on_event('DOMNodeInserted') do |event, node|
    DOMNodeInserted_on_home_page(event, node)
  end
  
  on_event('DOMNodeInserted', :url => SOME_OTHER_PAGE_URL) do |event, node|
    DOMNodeInserted_on_another_page(event, node)
  end
  
  on_event('DOMNodeInserted', :url => /should_not_be_called/) do |event, node|
    should_not_be_called(event, node)
  end
  
  def home_page_did_load(url, title); end
  def other_page_did_load(url, title); end
  def DOMNodeInserted_on_home_page(event, node); end
  def DOMNodeInserted_on_another_page(event, node); end
  def should_not_be_called(event, node); end
end

class GlobalUrlEventHandler2 < WebApp::EventHandler(GLOBAL_URL); end

describe "EventHandler, with a global url specified" do
  include EventHandlerSpecHelper
  
  before do
    @handler = GlobalUrlEventHandler.alloc.init
    stub_webview
  end
  
  it "should have a class instance variable which specifies the url" do
    GlobalUrlEventHandler.ivar(:global_url).should.be GLOBAL_URL
  end
  
  it "should increase the count in the name of the anonymous EventHandler subclass" do
    GlobalUrlEventHandler.name.should.not == GlobalUrlEventHandler2.name
  end
  
  it "should register event handlers with the document if options[:url] matches" do
    url, title = 'http://www.example.com/home', 'the home page'
    stub_url_and_title(url, title)
    
    @doc.expects(:addEventListener___).times(1).with('DOMNodeInserted', @handler, true)
    
    @handler.expects(:home_page_did_load).times(1).with(url, title)
    @handler.expects(:other_page_did_load).times(0).with(url, title)
    
    @handler.register_dom_observers!
  end
  
  it "should not register event handlers with the document if options[:url] does not match" do
    url, title = 'http://www.example.com/some_other_page', 'some other page'
    stub_url_and_title(url, title)
    
    @doc.expects(:addEventListener___).times(1).with('DOMNodeInserted', @handler, true)
    
    @handler.expects(:home_page_did_load).times(0).with(url, title)
    @handler.expects(:other_page_did_load).times(1).with(url, title)
    
    @handler.register_dom_observers!
  end
  
  it "should handle other real DOM events depending on wether or not the url matches" do
    @handler.register_dom_observers!
    
    event, node = stub('Event'), stub('Node')
    event.stubs(:relatedNode => node, :objc_send => 'DOMNodeInserted')
    node.stubs(:outerHTML => '', :attributes => {})
    
    @handler.expects(:DOMNodeInserted_on_home_page).times(1)
    @handler.expects(:DOMNodeInserted_on_another_page).times(0)
    @handler.expects(:should_not_be_called).times(0)
    @handler.handleEvent(event)
    
    stub_url_and_title('http://www.example.com/some_other_page', 'some other page')
    @handler.register_dom_observers!
    
    @handler.expects(:DOMNodeInserted_on_home_page).times(0)
    @handler.expects(:DOMNodeInserted_on_another_page).times(1)
    @handler.expects(:should_not_be_called).times(0)
    @handler.handleEvent(event)
  end
end