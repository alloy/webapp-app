require File.expand_path('../../test_helper', __FILE__)

describe 'WebAppBuilder' do
  before do
    @tmp = '/tmp/WebAppTest'
    FileUtils.mkdir_p @tmp
    
    @name = 'WebAppTestApplication'
    @url = 'https://foo.example.com'
    
    @bundle = WebAppBundle.new(File.expand_path('../../Fixtures/bundles/Foo.wabundle', __FILE__))
    
    @builder = WebAppBuilder.new(@name, @url, @tmp, @bundle, nil)
    @builder.create_base_application!
  end
  
  after do
    FileUtils.rm_rf @tmp
  end
  
  it "should unpack the WebApp base application and move it to the full path" do
    @builder.full_path.should == '/tmp/WebAppTest/WebAppTestApplication.app'
    File.should.exist @builder.full_path
  end
  
  it "should have created the correct Info.plist file" do
    plist = OSX::NSDictionary.dictionaryWithContentsOfFile path_to("Info.plist")
    plist['CFBundleIdentifier'].should == "nl.superalloy.webapp.#{@name}"
    plist['WebAppURL'].should == @url
  end
  
  it "should have created the correct InfoPlist.strings file" do
    strings = File.read path_to('Resources/English.lproj/InfoPlist.strings')
    copyright = "\"WebApp application\\nCopyright 2008 Eloy Duran <e.duran@superalloy.nl>.\""
    strings.should == "CFBundleName = \"WebAppTestApplication\";\nCFBundleGetInfoString = #{copyright};\nNSHumanReadableCopyright = #{copyright};"
  end
  
  it "should have copied the specified bundle to the bundles dir inside the app" do
    File.should.exist path_to('Resources/bundles/Foo.wabundle')
  end
  
  it "should not try to copy a bundle if none was selected" do
    FileUtils.expects(:cp_r).times(0)
    WebAppBuilder.new(@name, @url, @tmp, nil, nil).create_base_application!
  end
  
  it "should copy the icon file from the bundle if no optional icon was specified" do
    File.should.exist path_to('Resources/icon.tiff')
  end
  
  it "should copy the optionally specified icon instead of the one from the bundle" do
    WebAppBuilder.new(@name, @url, @tmp, @bundle, File.expand_path('../../Fixtures/other_icon.jpg', __FILE__)).create_base_application!
    File.should.exist path_to('Resources/other_icon.jpg')
  end
  
  private
  
  def path_to(file)
    File.join @builder.full_path, 'Contents', file
  end
end