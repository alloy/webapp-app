require File.expand_path('../../test_helper', __FILE__)

describe 'ApplicationController, in general' do
  tests ApplicationController
  
  def after_setup
    ib_outlets :bundles_menu => OSX::NSPopUpButton.alloc.init,
               :name_text_field => OSX::NSTextField.alloc.init,
               :url_text_field => OSX::NSTextField.alloc.init,
               :path_text_field => OSX::NSTextField.alloc.init
               
    path_text_field.stringValue = '/tmp'
    
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
    url_text_field.expects(:selectText).with(controller)
    
    url_text_field.stubs(:window).returns(main_window)
    responder = mock('First Responder')
    main_window.stubs(:firstResponder).returns(responder)
    responder.expects(:selectedRange=).with(OSX::NSRange.new(7..14))
    
    choose_preset 'Foo'
    name_text_field.stringValue.should == 'Foo'
    url_text_field.stringValue.should == 'http://CHANGEME.example.com/foo'
  end
  
  it "should empty the form elements if the 'None' preset is chosen" do
    name_text_field.stringValue = 'Foo'
    url_text_field.stringValue = 'http://foo.example.com'
    
    choose_preset 'None'
    
    name_text_field.stringValue.should.be.empty
    url_text_field.stringValue.should.be.empty
  end
  
  it "should start the creation process of a new webapp and open it in the finder when done" do
    @bundles['Foo'].stubs(:defaults).returns('name' => 'Foo', 'url' => 'http://foo.example.com')
    choose_preset 'Foo'
    
    builder = mock('WebAppBuilder')
    WebAppBuilder.expects(:new).with('Foo', 'http://foo.example.com', '/tmp').returns(builder)
    builder.expects(:create_base_application!)
    
    builder.stubs(:full_path).returns('/tmp/Foo.app')
    OSX::NSWorkspace.sharedWorkspace.expects(:selectFile_inFileViewerRootedAtPath).with('/tmp/Foo.app', '')
    
    controller.createApp(nil)
  end
  
  private
  
  def choose_preset(title)
    item = OSX::NSMenuItem.alloc.init
    item.title = title
    controller.presetChosen(item)
  end
end
