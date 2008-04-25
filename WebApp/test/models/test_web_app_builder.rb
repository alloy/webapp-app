require File.expand_path('../../test_helper', __FILE__)

describe 'WebAppBuilder' do
  before do
    @tmp = '/tmp/WebAppTest'
    FileUtils.mkdir_p @tmp
    
    @url = 'https://foo.example.com'
    
    @builder = WebAppBuilder.new('WebAppTestApplication', @url, @tmp)
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
    plist['WebAppURL'].should == @url
  end
  
  private
  
  def path_to(file)
    File.join @builder.full_path, 'Contents', file
  end
end