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
    
    image = mock('NSImage')
    OSX::NSImage.any_instance.expects(:initWithContentsOfFile).with(File.join(@bundles['Foo'].path, 'icon.tiff')).returns(image)
    icon_image_well.expects(:image=).with(image)
    
    choose_preset 'Foo'
    name_text_field.stringValue.should == 'Foo'
    url_text_field.stringValue.should == 'http://CHANGEME.example.com/foo'
  end
  
  it "should set the image to a empty image if no icon is present" do
    @bundles['Foo'].stubs(:defaults).returns('name' => 'Foo', 'url' => 'http://foo.example.com')
    @bundles['Foo'].stubs(:icon).returns(nil)
    icon_image_well.expects(:image=).with(ApplicationController::EMPTY_IMAGE)
    choose_preset 'Foo'
  end
  
  it "should empty the form elements if the 'None' preset is chosen" do
    name_text_field.stringValue = 'Foo'
    url_text_field.stringValue = 'http://foo.example.com'
    
    icon_image_well.expects(:image=).with(ApplicationController::EMPTY_IMAGE)
    choose_preset 'None'
    
    name_text_field.stringValue.should.be.empty
    url_text_field.stringValue.should.be.empty
  end
  
  it "should start the creation process of a new webapp and open it in the finder when done" do
    @bundles['Foo'].stubs(:defaults).returns('name' => 'Foo', 'url' => 'http://foo.example.com')
    choose_preset 'Foo'
    
    builder = mock('WebAppBuilder')
    WebAppBuilder.expects(:new).with('Foo', 'http://foo.example.com', '/tmp', @bundles['Foo']).returns(builder)
    builder.expects(:create_base_application!)
    
    builder.stubs(:full_path).returns('/tmp/Foo.app')
    OSX::NSWorkspace.sharedWorkspace.expects(:selectFile_inFileViewerRootedAtPath).with('/tmp/Foo.app', '')
    
    controller.createApp(nil)
  end
  
  it "should return the selected bundle" do
    item = OSX::NSMenuItem.alloc.init
    item.title = 'Foo'
    bundles_menu.stubs(:selectedItem).returns(item)
    
    controller.send(:selected_bundle).should == @bundles['Foo']
  end
  
  private
  
  def choose_preset(title)
    item = OSX::NSMenuItem.alloc.init
    item.title = title
    controller.stubs(:selected_bundle).returns(@bundles[title])
    controller.presetChosen(item)
  end
end
