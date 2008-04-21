require File.expand_path('../../test_helper', __FILE__)

describe "WebAppBundle, in general" do
  before do
    path = File.expand_path('../../Fixtures/bundles/Foo.wabundle', __FILE__)
    @bundle = WebAppBundle.new(path)
  end
  
  it "should return the display name" do
    @bundle.display_name.should == 'Foo'
  end
  
  it "should return it's default values" do
    @bundle.defaults.should == { 'name' => 'Foo', 'url' => 'http://CHANGEME.example.com/foo' }
  end
end

describe "WebAppBundle, class methods" do
  it "should return an hash of bundles" do
    Rucola::RCApp.stubs(:root_path).returns(File.expand_path('../../Fixtures', __FILE__))
    bundles = WebAppBundle.bundles
    bundles.length.should.be 1
    bundles['Foo'].display_name.should == 'Foo'
  end
end