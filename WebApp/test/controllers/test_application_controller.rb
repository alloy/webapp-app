require File.expand_path('../../test_helper', __FILE__)

describe 'ApplicationController, in general' do
  tests ApplicationController
  
  def after_setup
    ib_outlets :bundles_menu => OSX::NSPopUpButton.alloc.init,
               :name_text_field => OSX::NSTextField.alloc.init,
               :url_text_field => OSX::NSTextField.alloc.init
               
    
    @bundles = { 'Foo' => WebAppBundle.new(File.expand_path('../../fixtures/bundles/Foo.wabundle', __FILE__)) }
    WebAppBundle.stubs(:bundles).returns(@bundles)
  end
  
  it "should return an array of existing bundles" do
    controller.send(:bundles).should == @bundles
  end
  
  it "should return an array of menu items for existing bundles" do
    controller.send(:awakeFromNib)
    bundles_menu.itemArray.length.should.be 1
    
    item = bundles_menu.itemArray.first
    item.title.to_s.should == 'Foo'
    item.target.should.be controller
    item.action.should == 'presetChosen:'
  end
  
  it "should set defaults if a preset was chosen" do
    choose_preset 'Foo'
    name_text_field.stringValue.should == 'Foo'
    url_text_field.stringValue.should == 'http://foo.example.com'
  end
  
  it "should empty the form elements if the 'None' preset is chosen" do
    name_text_field.stringValue = 'Foo'
    url_text_field.stringValue = 'http://foo.example.com'
    
    choose_preset 'None'
    
    name_text_field.stringValue.should.be.empty
    url_text_field.stringValue.should.be.empty
  end
  
  private
  
  def choose_preset(title)
    item = OSX::NSMenuItem.alloc.init
    item.title = title
    controller.presetChosen(item)
  end
end
