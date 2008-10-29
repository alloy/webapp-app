require File.expand_path('../../test_helper', __FILE__)

describe 'ApplicationController, in general' do
  tests ApplicationController
  
  def after_setup
    ib_outlets :steps_tab_view => OSX::NSTabView.alloc.init,
               :url_text_field => OSX::NSTextField.alloc.init,
               :continue_button => OSX::NSButton.alloc.init
    
    @first_step, @second_step = Array.new(2) do |i|
      item = OSX::NSTabViewItem.alloc.initWithIdentifier(i+1)
      steps_tab_view.addTabViewItem item
      item
    end
    
    @bundle = WebAppBundle.alloc.initWithPath(File.expand_path('../../fixtures/bundles/Foo.wabundle', __FILE__))
    WebAppBundle.stubs(:bundles).returns([@bundle])
  end
  
  it "should allow the user to advance to the creation step once a valid url has been given" do
    should_not_enable_continue_button { controller.url = 'http://' }
    should_not_enable_continue_button { controller.url = 'https://example' }
    
    should_enable_continue_button { controller.url = 'http://example.com' }
    should_enable_continue_button { controller.url = 'https://example.com' }
    should_enable_continue_button { controller.url = 'https://example.com/foo/bar' }
  end
  
  it "should figure out the bundle for a given url and advance to the creation step" do
    assigns(:url, 'https://example.com/foo')
    
    controller.expects(:bundle=).with(@bundle)
    controller.expects(:name=).with(@bundle.name)
    controller.nextStep(controller)
    steps_tab_view.selectedTabViewItem.should.be @second_step
  end
  
  it "should still be able to advance to the creation step if no bundle was found for the given url" do
    assigns(:url, 'https://example.com/bar')
    
    controller.nextStep(controller)
    steps_tab_view.selectedTabViewItem.should.be @second_step
    controller.bundle.should.be nil
    controller.name.should.be nil
  end
  
  it "should start the creation process of a new webapp and open it in the finder when done" do
    assigns(:bundle, @bundle)
    assigns(:url, 'https://example.com/foo')
    assigns(:name, 'MyFoo')
    
    builder = mock('WebAppBuilder')
    WebAppBuilder.expects(:new).with('MyFoo', 'https://example.com/foo', '/Applications', @bundle).returns(builder)
    builder.expects(:create_base_application)
    
    builder.stubs(:full_path).returns('/Applications/MyFoo.app')
    OSX::NSWorkspace.sharedWorkspace.expects(:selectFile_inFileViewerRootedAtPath).with('/Applications/MyFoo.app', '')
    
    controller.createApp(self)
  end
  
  private
  
  def should_not_enable_continue_button
    continue_button.enabled = false
    yield
    continue_button.isEnabled.should.be false
  end
  
  def should_enable_continue_button
    continue_button.enabled = false
    yield
    continue_button.isEnabled.should.be true
  end
end
