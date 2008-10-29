require File.expand_path('../../test_helper', __FILE__)

describe "WebAppBundle, in general" do
  before do
    @path = File.expand_path('../../Fixtures/bundles/Foo.wabundle', __FILE__)
    @bundle = WebAppBundle.alloc.initWithPath(@path)
  end
  
  it "should return the name of bundle" do
    @bundle.name.should == 'Foo'
  end
  
  it "should return a path to a icon file if there is one in the bundle" do
    @bundle.icon.should == File.join(@path, 'icon.tiff')
  end
  
  it "should return wether or not it matches a given url" do
    @bundle.should.not.url_match 'http://'
    @bundle.should.not.url_match 'http://example/com'
    
    @bundle.should.url_match 'http://example.com/foo'
    @bundle.should.url_match 'https://example.com/foo'
  end
end

describe "WebAppBundle, class methods" do
  before do
    Rucola::RCApp.stubs(:root_path).returns(File.expand_path('../../Fixtures', __FILE__))
  end
  
  it "should return an array of bundles" do
    bundles = WebAppBundle.bundles
    bundles.length.should.be 1
    bundles.first.name.should == 'Foo'
  end
  
  it "should return a bundle that matches a given url" do
    foo = WebAppBundle.bundles.first
    WebAppBundle.bundle_for_url('http://example.com/foo').should.be foo
    WebAppBundle.bundle_for_url('https://example.com/foo').should.be foo
  end
end