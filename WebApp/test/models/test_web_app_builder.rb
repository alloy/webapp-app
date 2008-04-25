require File.expand_path('../../test_helper', __FILE__)

describe 'WebAppBuilder' do
  before do
    @tmp = '/tmp/WebAppTest'
    FileUtils.mkdir_p @tmp
    @builder = WebAppBuilder.new('WebAppTestApplication', @tmp)
  end
  
  after do
    FileUtils.rm_rf @tmp
  end
  
  it "should return the full path to the application" do
    @builder.full_path.should == '/tmp/WebAppTest/WebAppTestApplication.app'
  end
  
  it "should unpack the WebApp base application and move it to the full path" do
    @builder.create_base_application!
    File.exist?(@builder.full_path).should.be true
  end
end