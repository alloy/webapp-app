require File.expand_path('../../test_helper', __FILE__)

describe 'ApplicationController, in general' do
  tests ApplicationController
  
  def after_setup
    ib_outlets :bundles_menu => OSX::NSPopUpButton.alloc.init,
               :name_text_field => OSX::NSTextField.alloc.init,
               :url_text_field => OSX::NSTextField.alloc.init
               
    @bundles = ['Foo.wabundle', 'Bar.wabundle']
    @bundle_names = @bundles.map { |name| name.sub(/\.wabundle$/, '') }
  end
  
  it "should return an array of existing bundles" do
    Dir.stubs(:glob).with("#{Rucola::RCApp.root_path}/bundles/*.wabundle").returns(@bundles.map { |name| "/some/path/to/webapp/#{name}" })
    controller.send(:bundles).should == @bundle_names
  end
  
  it "should return an array of menu items for existing bundles" do
    controller.stubs(:bundles).returns(@bundle_names)
    controller.send(:awakeFromNib)
    bundles_menu.itemArray.map { |item| item.title.to_s }.should == @bundle_names
    bundles_menu.itemArray.each do |item|
      item.target.should.be controller
      item.action.should == 'presetChosen:'
    end
  end
  
  it "should set defaults if a preset was chosen" do
    defaults = {
      'Foo' => { 'name' => 'Foo', 'url' => 'http://foo.example.com' },
      'Bar' => { 'name' => 'Bar', 'url' => 'http://bar.example.com' }
    }.to_ns
    
    controller.stubs(:bundles).returns(@bundle_names)
    controller.stubs(:defaults).returns(defaults)
    
    item = OSX::NSMenuItem.alloc.init
    item.title = 'Bar'
    controller.presetChosen(item)
    
    name_text_field.stringValue.should == 'Bar'
    url_text_field.stringValue.should == 'http://bar.example.com'
  end
  
  it "should empty the form elements if the 'None' preset is chosen" do
    name_text_field.stringValue = 'Foo'
    url_text_field.stringValue = 'http://foo.example.com'
    
    item = OSX::NSMenuItem.alloc.init
    item.title = 'None'
    controller.presetChosen(item)
    
    name_text_field.stringValue.should.be.empty
    url_text_field.stringValue.should.be.empty
  end
end
