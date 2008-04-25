require File.expand_path('../../test_helper', __FILE__)

describe 'WebAppBuilder' do
  before do
    OSX::NSUserDefaults.standardUserDefaults.stubs(:[]).with('CFBundleVersion').returns('91.123')
    
    @tmp = '/tmp/WebAppTest'
    FileUtils.mkdir_p @tmp
    
    @name = 'WebAppTestApplication'
    @url = 'https://foo.example.com'
    
    @builder = WebAppBuilder.new(@name, @url, @tmp)
    @builder.create_base_application!
  end
  
  after do
    FileUtils.rm_rf @tmp
  end
  
  it "should unpack the WebApp base application and move it to the full path" do
    @builder.full_path.should == '/tmp/WebAppTest/WebAppTestApplication.app'
    File.exist?(@builder.full_path).should.be true
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
  
  private
  
  def path_to(file)
    File.join @builder.full_path, 'Contents', file
  end
end