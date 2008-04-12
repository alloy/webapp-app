require File.expand_path('../../test_helper', __FILE__)

describe 'ApplicationController, in general' do
  tests ApplicationController
  
  def after_setup
    @bundles = ['Foo.wabundle', 'Bar.wabundle']
  end
  
  it "should return an array of existing bundles" do
    Dir.stubs(:glob).with("#{Rucola::RCApp.root_path}/bundles/*.wabundle").returns(@bundles.map { |name| "/some/path/to/webapp/#{name}" })
    controller.send(:bundles).should == @bundles
  end
  
  it "should return an array of menu items for existing bundles" do
    controller.stubs(:bundles).returns(@bundles)
    controller.send(:bundle_menu_items).each_with_index do |menu_item, idx|
      menu_item.should.be.instance_of OSX::NSMenuItem
      menu_item.title.should == @bundles[idx]
    end
  end
end
